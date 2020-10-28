output "Kubernetes_master_and_bastion" {
    description = "Kubernetes master and bastion"
    value       = aws_instance.k8s_master[0].public_ip
}

output "jenkins_port" {
    description = "Connect to Jenkins on this port"
    value       = var.jenkins_console_port
}

output "jenkins_master_address" {
    description = "Connect to Jenkins on this IP"
    value       = aws_instance.jenkins_master[0].public_ip
}

output "db_endpoint" {
    description = "Connect to Jenkins on this IP"
    value       = aws_db_instance.db[0].endpoint
}

output "elb_dns" {
    description = "Connect to application"
    value       = aws_lb.final_lb.dns_name
}