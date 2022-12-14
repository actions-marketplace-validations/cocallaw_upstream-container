FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04

COPY run-check.ps1 /run-check.ps1
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]