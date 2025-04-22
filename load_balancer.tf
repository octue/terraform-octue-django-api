resource "google_compute_region_network_endpoint_group" "load_balancer_neg" {
  name                  = "${var.resource_affix}--lb-neg--${var.environment}"
  network_endpoint_type = "SERVERLESS"
  project               = var.google_cloud_project_id
  region                = var.google_cloud_region
  cloud_run {
    service = google_cloud_run_v2_service.server.name
  }
}

resource "google_compute_backend_service" "load_balancer_backend" {
  connection_draining_timeout_sec = 0
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  name                            = "${var.resource_affix}--lb-backend--${var.environment}"
  port_name                       = "http"
  project                         = var.google_cloud_project_id
  protocol                        = "HTTPS"
  session_affinity                = "NONE"
  timeout_sec                     = 30
  locality_lb_policy              = "ROUND_ROBIN"

  backend {
    balancing_mode               = "UTILIZATION"
    capacity_scaler              = 1
    group                        = google_compute_region_network_endpoint_group.load_balancer_neg.self_link
    max_connections              = 0
    max_connections_per_endpoint = 0
    max_connections_per_instance = 0
    max_rate                     = 0
    max_rate_per_endpoint        = 0
    max_rate_per_instance        = 0
    max_utilization              = 0
  }
}


resource "google_compute_global_address" "ip" {
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
  name         = "${var.resource_affix}--ip--${var.environment}"
  project      = var.google_cloud_project_id
}


resource "google_compute_managed_ssl_certificate" "ssl" {
  name    = "${var.resource_affix}--ssl--${var.environment}"
  project = var.google_cloud_project_id

  managed {
    domains = [
      var.api_url
    ]
  }

  timeouts {}
}


resource "google_compute_global_forwarding_rule" "load_balancer_frontend" {
  ip_address            = google_compute_global_address.ip.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  name                  = "${var.resource_affix}--lb-frontend--${var.environment}"
  port_range            = "443-443"
  project               = var.google_cloud_project_id
  target                = "https://www.googleapis.com/compute/beta/projects/${var.google_cloud_project_id}/global/targetHttpsProxies/${google_compute_target_https_proxy.load_balancer_target_https_proxy.name}"
}


resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  ip_address            = google_compute_global_address.ip.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  name                  = "${google_compute_global_forwarding_rule.load_balancer_frontend.name}-forwarding-rule"
  port_range            = "80-80"
  project               = var.google_cloud_project_id
  target                = "https://www.googleapis.com/compute/beta/projects/${var.google_cloud_project_id}/global/targetHttpProxies/${google_compute_target_http_proxy.redirect_target_http_proxy.name}"
}


resource "google_compute_url_map" "http_redirect" {
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }

  name        = "${google_compute_global_forwarding_rule.load_balancer_frontend.name}-redirect"
  project     = var.google_cloud_project_id
  description = "Automatically generated HTTP to HTTPS redirect for the ${google_compute_global_forwarding_rule.load_balancer_frontend.name} forwarding rule"
}


resource "google_compute_target_http_proxy" "redirect_target_http_proxy" {
  name    = "${google_compute_global_forwarding_rule.load_balancer_frontend.name}-target-proxy"
  project = var.google_cloud_project_id
  url_map = "https://www.googleapis.com/compute/v1/projects/${var.google_cloud_project_id}/global/urlMaps/${google_compute_url_map.http_redirect.name}"
}


resource "google_compute_target_https_proxy" "load_balancer_target_https_proxy" {
  name             = "${var.resource_affix}--lb-target-proxy--${var.environment}"
  project          = var.google_cloud_project_id
  quic_override    = "NONE"
  ssl_certificates = ["https://www.googleapis.com/compute/v1/projects/${var.google_cloud_project_id}/global/sslCertificates/${google_compute_managed_ssl_certificate.ssl.name}"]
  url_map          = "https://www.googleapis.com/compute/v1/projects/${var.google_cloud_project_id}/global/urlMaps/${google_compute_url_map.load_balancer.name}"
}


resource "google_compute_url_map" "load_balancer" {
  default_service = "https://www.googleapis.com/compute/v1/projects/${var.google_cloud_project_id}/global/backendServices/${google_compute_backend_service.load_balancer_backend.name}"
  name            = "${var.resource_affix}--lb--${var.environment}"
  project         = var.google_cloud_project_id
}
