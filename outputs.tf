output "jenkins_address" {
    description = "Connect to Jenkins on this IP"
    value       = aws_instance.jenkins[0].public_ip
}

output "jenkins_port" {
    description = "Connect to Jenkins on this IP"
    value       = var.jenkins_console_port
}
