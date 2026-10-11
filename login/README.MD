## Login 

### Table of Contents
        1. Overview 
        2. Access Control Model 
        3. Sudo Configuration   
        4. Password Policy  
            4.1 Password Aging (chage)  
            4.2 Account Lockout (PAM)   
        5. Shared Directories   
            5.1 Project Directory   
            5.2 Scratch Directory   
            5.3 Mechanism Table 
        6. SSH Hardening    
        7. Verification Script  
        8. Repository Structure 
        9. Security Principles & Conclusion  

### 1. Overview

This project creates an access control policy on a server that is shared by three roles: administrator, developer and deployer. This project aims to apply the principle of least privilege. This project ensures that each role can do the actions that its job needs and nothing more.

The policy covers:

- User and group management with one group for each role.
- Command-scoped sudo rules stored in `/etc/sudoers.d/`.
- Password aging (`chage`) and account lockout (PAM).
- A shared project directory protected with POSIX ACLs and special bits (`setgid` and sticky).
- Key-based SSH authentication with password login disabled.
- An automated verification script (`verify.sh`) that proves each restriction actually holds.
All roles interact with the systemd service `myservice.service` which was created in the `linux` project. This project verifies every claim in this document using `verify.sh` rather than assuming it is true.

### 2. Access Control Model

### 4. Password Policy

* **4.1. Password Aging (chage)**
    
* **4.2. Account Lockout (PAM)**