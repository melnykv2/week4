[webservers]
%{ for idx, id in app_instance_ids ~}
app${idx + 1} ansible_host=${id}
%{ endfor ~}

[dbservers]
db ansible_host=${db_instance_id}

[webservers:vars]
ansible_connection=aws_ssm
ansible_aws_ssm_region=${region}
ansible_aws_ssm_bucket_name=${s3_bucket_name}
ansible_python_interpreter=/usr/bin/python3
db_host=${db_private_ip}
db_password_parameter=${db_password_parameter}
django_secret_parameter=${django_secret_parameter}
alb_dns_name=${alb_dns_name}

[dbservers:vars]
ansible_connection=aws_ssm
ansible_aws_ssm_region=${region}
ansible_aws_ssm_bucket_name=${s3_bucket_name}
ansible_python_interpreter=/usr/bin/python3
db_password_parameter=${db_password_parameter}
