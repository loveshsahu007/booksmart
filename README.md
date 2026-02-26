# BookSmart


## DataModels
- all should have default/auto-generated id from supabase
- use id for foreign key
- use enum for type/roles where possible, avoid string comparison
- in User role; models should depend on organizationId, i.e. transaction, bank etc


## Controllers
- in User role; controllers should depend on organizationId, i.e. transaction, bank etc

## Pending
- on web, when user have no organization, then it will navigate user to a route, that is temporary. we have to fix it later on, for better navigation

## Supabase Tables
- id type should be int8 and from setting icon set it to IDENTITY

## TODO
- confirm transaction TYPE again, and also adjust it in case of PLAID ... 


Plaid Test username
username: user_good
password: pass_good