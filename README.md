# CIS Playground

## Quick Start

Put your credentials into the environment (script has a default of extracting
from hwine's password store, but you can ignore that).
```shell
CLIENT_ID=your_id
CLIENT_SECRET=your_secret
```
Source the functions (taken from [the
docs](https://github.com/mozilla-iam/cis/blob/master/docs/PersonAPI.md#do-you-have-code-examples),
then expanded)
```shell
.  shell_functions
```

Use the function -- they all start with "person", so type that, then use tab
completion to see what's there (it changes over time):
```shell
$ person-api-<tab><tab>
person-api-all                 person-api-metadata
person-api-attribute-contains  person-api-userid
person-api-email               person-api-username
$ person-api-
```

Have fun!

# Current investigations

## Field mapping

- `person-api-metadata` takes an email address. Always succeeds, but returns
  all `false` if user not in system.


## Current Stumpers (maybe bugs)

The following calls always seem to generate a 500 error:
- `person-api-attribute-contains staff_information.staff=True` (taken
  from docs)
- `person-api-all`

