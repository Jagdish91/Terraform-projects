
# 🌩️ Terraform AWS Infrastructure: Multi-AZ Web App with ALB & EC2

Deployed a production-like web application using **Terraform**, **AWS**, and **Infrastructure-as-Code (IaC)**. This project demonstrates real-world cloud architecture, automation, and security awareness.

---

## 🧩 Project Overview

This project builds a **highly available, multi-AZ web app** on AWS using:
- ✅ VPC with public subnets across two Availability Zones
- ✅ Application Load Balancer (ALB) routing traffic to two EC2 instances
- ✅ EC2 instances running Apache via `user_data`
- ✅ S3 bucket for static assets (future use)
- ✅ Security Groups allowing HTTP/SSH (currently open to 0.0.0.0/0 — *security improvement planned*)

> ⚠️ **Note**: This is a **learning environment**. In production, EC2 instances would be in **private subnets**, SSH access restricted, and the ALB would handle all inbound traffic.

---

## 🛠️ Key Features

| Feature | Implemented |
|-------|------------|
| Terraform IaC | ✅ |
| Multi-AZ VPC & Subnets | ✅ |
| ALB + Target Group | ✅ |
| EC2 Auto-Config via `user_data` | ✅ |
| S3 Bucket Creation | ✅ |
| Public Subnet Deployment | ✅ |
| Security Group Hardening (planned) | 🔜 |
| Private Subnet Migration (planned) | 🔜 |

---
