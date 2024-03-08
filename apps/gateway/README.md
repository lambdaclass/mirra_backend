# Gateway

After starting all applications with `make start`, you can start sending requests to the gateway.

To make testing easier, we created the SocketTester module, which allows you to send requests to the gateway using the command line.

You can start the SocketTester by running the following command:

```
iex(1)> {_ok, pid} = SocketTester.start_link
```

To create a new user called JohnDoe in Champions of Mirra, you can run the following command:

```
iex(2)> SocketTester.create_user(pid, "JohnDoe")
```

This should log the Gateway's response with the new user.

To get all the campaigns available to that user in Champions of Mirra, you can run the following command (replace `user_id` with the user id returned in the previous request):

```
iex(3)> SocketTester.get_campaigns(pid, "user_id")
```

Now, to play a battle in the first level of the first campaign, get the level ids from the previous request and run the following command (replace `level_id` with the corresponding fields returned in the previous request):

```
iex(4)> SocketTester.fight_level(pid, "user_id", "level_id")
```
