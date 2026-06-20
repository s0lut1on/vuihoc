import subprocess

vps = "root@194.233.94.167"

print("=== A. What keys does VPS have? ===")
out = subprocess.run(
    ["ssh", "-o", "BatchMode=yes", vps, "ls -la /root/.ssh/"],
    capture_output=True, text=True
)
print(out.stdout or out.stderr)
print()

print("=== B. What key did VPS use for the failed auth? (verbose) ===")
out = subprocess.run(
    ["ssh", "-o", "BatchMode=yes", vps,
     "ssh -vvv -o BatchMode=yes -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1"],
    capture_output=True, text=True
)
for line in out.stdout.splitlines():
    if any(k in line.lower() for k in ['offering', 'authentication', 'publickey', 'loaded', 'identity', 'permission', 'succeeded', 'denied']):
        print(f"  {line}")
print()

print("=== C. Verify the math_app_deploy private key on VPS still has the right pubkey ===")
out = subprocess.run(
    ["ssh", "-o", "BatchMode=yes", vps,
     "ssh-keygen -y -f /root/.ssh/math_app_deploy 2>&1 || echo NO_KEY_FILE"],
    capture_output=True, text=True
)
print(out.stdout)
