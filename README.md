# Windowns_sandbox_ansible
Example script and setting for running Ansible playbook in Windows Sandbox Environment.  
The script makes Windows Sandbox environment to test software or library easily.
The script will do the below things
- Install Chocolatey(for installing all of the below software)
- Install Cygwin(for running ansible)
- Setup WinRM using ConfigureRemotingForAnsible.ps1 see [here](https://docs.ansible.com/ansible/2.9/user_guide/windows_setup.html#winrm-setup)
- Change the WDAGUtilityAccount password to you'll input when run "run_setup.ps1" at first.

# Usage
1. Enable Windows Sandbox  
  https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-sandbox/windows-sandbox-overview

2. double click test.wsb file, it will open the Windows Sandbox environment.

3. move "run_setup.ps1" and "dev_playbook.yml" to Windows sandbox.
    - just copying both files to Windows sandbox("Ctrl+C", "Ctrl+V" works)
    - Also, you can share the host folder to edit test.web "MappedFolder" Section see [here](https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-sandbox/windows-sandbox-configure-using-wsb-file#mapped-folders)

4. execute run_setup.ps1 like the below.
    ```
    Powershell -ExecutionPolicy RemoteSigned -File "C:\Users\WDAGUtilityAccount\Desktop\setup\run_setup.ps1"
    ```  
    input password for WDAGUtilityAccount (Windows Sandbox Account)  
    **The action overwrites WDAGUtilityAccount Password**.

5. tools and software will install through "ansible-playbook" based on dev_playbook.yml.  
  by default, git,VSCode,SourceTree and notepad++ 

# Checked OS environments
| Name | Info |
|------|:--------:|
| Edition | Windows 10 Pro |
| Version | 21H2 |
| OS Build No | 19044.1889 |
