# facter-statistax
Benchmark tool for different versions of Puppet Facter.

In order to run this script you must create a 'config.json' file with the following format:

```
[
  {
    "test_run":"TestRun1",
    "runs":[
      {
        "fact":"os",
        "repetitions":3
      },
      {
        "fact":"os uptime",
        "repetitions":1
      },
      {
        "fact":"all",
        "repetitions":3
      }
    ]
  }
]
```

After you create the config file, run: 'ruby /bin/statistax.rb'.

statistax.rb can receive as parameter a path to facter binary:

'ruby /bin/statistax.rb path' -> 'ruby /bin/statistax.rb /opt/puppetlabs/bin/facter' 

You will find all the output from all runs in log/facter_statistax.log.
