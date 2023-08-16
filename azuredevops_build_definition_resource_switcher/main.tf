locals {
  yml_prefix_name = var.repository.yml_prefix_name == null ? "" : "${var.repository.yml_prefix_name}-"

}


