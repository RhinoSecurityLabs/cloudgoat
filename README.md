# CloudGoat
Rhino Security Labs' AWS penetration testing "Vulnerable by Design" AWS infrastructure setup tool

## Note
- The Glue development endpoint is disabled by default due to it costing far more than the whole rest of CloudGoat to run. If you would like to enable to Glue development endpoint (estimated at $1 per hour), uncomment the final three lines of "start.sh", uncomment the final eight lines of "kill.sh", and uncomment the file located at "./terraform/glue.tf".
