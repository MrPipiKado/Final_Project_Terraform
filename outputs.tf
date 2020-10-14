output "jenkins_address" {
    description = "Connect to Jenkins on this IP"
    value       = aws_instance.jenkins[0].public_ip
}

output "jenkins_port" {
    description = "Connect to Jenkins on this port"
    value       = var.jenkins_console_port
}

output "db_endpoint" {
    description = "Connect to Jenkins on this IP"
    value       = aws_db_instance.db[0].endpoint
}