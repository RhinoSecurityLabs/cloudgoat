# rce-web-app
A super-simple app developed for CloudGoat's rce_web_app scenario.

- Run the app via `node .`.
- All static files are placed at */static* folder, which behaves like a file root for server: *static/foo.bar* can be accessed via *localhost:9000/foo.bar*.
- "Secret" HTML page is mkja1xijqf0abo1h9glg.html.
- Port is set via CLI argument (9000 by default) `node . 3000`
- No need to install dependencies (no `npm install` needed), just run the command above.

**Note:** the app is pre-zipped to avoid requiring `zip` on the user's computer. If you make any changes to the app files, you must also update the zip!
