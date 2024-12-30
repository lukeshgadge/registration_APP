
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets

}
/*
output "jenkins_mainserver_public_ip" {
  value = aws_instance.jenkins_mainserver.public_ip
  
}
*/
output "security_groups" {
  value = aws_security_group.allow_tls.id

}

output "vpc_security_group" {
  value = module.vpc.default_vpc_default_security_group_id
}

output "jenkins_mainserver_public_ip" {
  value = aws_instance.jenkins_mainserver.public_ip
}


output "iam_admin_name" {
  value = aws_iam_instance_profile.example_profile.name
}