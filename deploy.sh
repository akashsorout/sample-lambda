#!/bin/bash


pip install -r requirement.txt -t package/
cp lambda_function.py package/
zip -r "lambda.zip" package/ 
terraform init
terraform apply