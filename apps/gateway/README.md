# Gateway

After starting all applications with `make start`, you can start sending requests to the gateway.

For example, to create a new user called JohnDoe in Champions of Mirra, you can run the following command:

```
$ curl --request POST http://localhost:4000/championsofmirra/users/JohnDoe
```

This should return a response with the new user.

To get all the campaigns available to that user in Champions of Mirra, you can run the following command (replace `:user_id` with the user id returned in the previous request):

```
$ curl --request GET http://localhost:4000/championsofmirra/users/:user_id/campaigns
```

Now, to play a battle in the first level of the first campaign, get the level id from the previous request and run the following command (replace `:level_id` with the level id returned in the previous request):

```
$ curl --request POST http://localhost:4000/championsofmirra/users/:user_id/levels/:level_id/battle
```
