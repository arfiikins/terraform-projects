#!/bin/bash
sudo yum install mysql -y
sudo systemctl start mysqld
sudo systemctl enable mysqld