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

After you create the config file, run: ```statistax path_to_config_file (true)```.

statistax.rb can receive true or false. True means that you want to measure facter gem, false is for c++ facter (the 3rd parameter is by default "false"). 

You will find all the output from all runs in log/facter_statistax.log.
