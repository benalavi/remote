Remote
======

Remote is a small tool for running bash scripts on a collection of remote
servers. It consists of a small library which handles compiling and running
bash scripts on remote servers, a "task" library which can be used inside of
rake tasks which adds some conventions, and a handful of common tasks.

This is all pretty experimental and non-flushed-out, so expect the API to
change wildly :)

Remote is heavily inspired by [relay](https://github.com/soveran/relay) and
[tele](https://github.com/djanowski/tele).

Usage
-----

To use the remote rake tasks, in your `rakefile`:

    $:.unshift("vendor/remote/lib")
    Dir["vendor/remote/lib/tasks/**/*.rake"].each{ |r| import File.expand_path(r) }

Using the remote lib:

`~/Sites/my_app/config/ssh_config`:

    Host development
      Hostname 33.33.33.144
      User vagrant
      
    Host production-1
      Hostname 127.0.0.1
      User root
      
    Host production-2
      Hostname 127.0.0.2
      User root

    remote = Remote.new "~/Sites/my_app/deploy/ssh_config", verbose: true
    remote.run %w( production-1 production-2 ), %w( ~/Sites/my_app/deploy/recipes/env.sh ~/Sites/my_app/deploy/recipes/provision.sh )

Provisioning & Deployment
-------------------------

Remote comes with a `remote:deploy` task which can be used to provision a set
of servers and/or deploy code to them. The setup is similar to
[tele](https://github.com/djanowski/tele):

`/deploy/layout.json` describes the environments, servers, and roles you will
be deploying to:

    {
      "roles": {
        "dev": [ "env", "admin", "ruby", "unicorn", "nginx", "gems", "deploy", "development" ],
        "app": [ "env", "admin", "ruby", "unicorn", "nginx", "gems", "deploy" ],
        "db": [ "env", "admin", "postgresql" ]
      },
      "environments": {
        "development": {
          "dev": "development"
        }
        "staging": {
          "app": "staging",
          "db": "staging"
        },
        "production": {
          "app": [
            "production-1",
            "production-2",
            "production-3",
            "production-4"
          ],
          "db": "production-db"
        }
      }
    }

`deploy/ssh_config` contains an application-specific SSH configuration for your
servers:

    Host development
      Hostname 33.33.33.144
      User vagrant
    
    Host staging
      Hostname 192.0.43.20
      User root
    
    Host production-db
      Hostname 192.0.43.10
      User root
    Host production-1
      Hostname 192.0.43.11
      User root
    Host production-2
      Hostname 192.0.43.12
      User root
    Host production-3
      Hostname 192.0.43.13
      User root
    Host production-4
      Hostname 192.0.43.14
      User root

Finally, the "roles" in `layout.json` define the names of recipes to be run in
`deploy/recipes`. So tying it all together, running
`rake remote:deploy ENV=production` would run the scripts (in the order
defined):

    deploy/recipes/env.sh
    deploy/recipes/admin.sh
    deploy/recipes/ruby.sh
    deploy/recipes/unicorn.sh
    deploy/recipes/nginx.sh
    deploy/recipes/gems.sh
    deploy/recipes/deploy.sh
    
On the `production-1`, `production-2`, `production-3` & `production-4` servers.
Then it would run the scripts:

    deploy/recipes/env.sh
    deploy/recipes/admin.sh
    deploy/recipes/postgresql.sh
    
On the `production-db` server.

See [remote-recipes](https://github.com/benalavi/remote-recipes) for an
example collection of bash scripts.

Writing Recipes
---------------

Remote compiles all the bash scripts into a single script before running them
on the remote servers. This way they all run in a single session and can share
an environment (provided you pass the environment via `-E` any time you use 
`sudo`).
