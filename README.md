# writeas-vala

Unofficial [Write.as](https://write.as) API client library for Vala. Still a work in progress.

## Compilation

### Requirements

```
meson
ninja-build
valac
libgtk-3-dev
```

### Building

```bash
meson build
cd build
meson configure -Denable_examples=true
ninja
./examples/hello-writeas
```

Examples require update to username and password, don't check this in

```
string user = "username";
string password = "password";
```

# Quick Start

## New Login

```vala
Writeas.Client client = new Writeas.Client ();
string access_token;
if (client.authenticate ("user", "pass", out access_token)) {
    print ("You logged in! Now get writing!");
}
```

## Existing auth token

```vala
Writeas.Client client = new Writeas.Client ();
string access_token = "token-read-from-datastore";
if (client.set_token (access_token)) {
    print ("You're already logged in! Now get back to writing!");
} else {
    // Access token expired, reauth user
}
```

## Determining who's logged in

```vala
bool client.get_authenticated_user (out string username)
```

Returns true if there's an existing access token and it's still valid. Username will be set.

False if the user is anonymous or if the access token is invalid. Username will be null.

## Get user posts

```vala
GLib.List<Writeas.Post> posts = new GLib.List<Writeas.Post> ();
bool client.get_user_posts (ref posts);
```

Returns true if auth token is valid, and populates posts with posts.

Returns false and leaves posts empty otherwise.

```vala
public class Writeas.Post {
    public string id { get; set; }
    public string slug { get; set; }
    public string appearance {get; set; }
    public string language { get; set; }
    public bool rtl { get; set; }
    public string created { get; set; }
    public string updated { get; set; }
    public string title { get; set; }
    public string body { get; set; }
    public string[] tags { get; set; }
    public int views { get; set; }
    public Writeas.Collection collection { get; set; }
    public string token { get; set; }
}

public class Writeas.Collection {
    public string alias { get; set; }
    public string title { get; set; }
    public string description { get; set; }
    public string style_sheet  { get; set; }
    public bool @public { get; set; }
    public int views { get; set; }
    public string email { get; set; }
    public string url { get; set; }
    public string monetization_pointer { get; set; }
}
```

## Get user collections

```vala
GLib.List<Writeas.Collection> collections = new GLib.List<Writeas.Collection> ();
bool client.get_user_collections (ref collections);
```

Returns true if auth token is valid, and populates collections with collections.

Returns false and leaves collections empty otherwise.

## Render Markdown

```vala
bool client.render_markdown (out string formatted_markdown, string markdown)
```

When returns true, formatted_markdown will contain the resulting HTML from the markdown.

## Publish a Post

```vala
bool client.publish_post (
            out string token,
            out string id,
            string body,
            string title,
            string font = "serif",
            string lang = "en",
            bool rtl = false,
            string created = "",
            string user_token = "")
```

Returns true if post is published, false if the post is not published.

Can be used without logging in.

## Publish Post to Collection

```vala
bool client.publish_collection_post (
            out string token,
            out string id,
            string collection_alias,
            string body,
            string title,
            string font = "serif",
            string lang = "en",
            bool rtl = false,
            string created = "",
            string user_token = "")
```

Returns true if post is published, false if the post is not published.

User must be logged in.

## Getting a Post

```vala
Writeas.Post post;
bool client.get_post (out Writeas.Post post, string post_id)
```

Returns true if post exists and was obtained, false otherwise.

## Updating a Post

```vala
bool client.update_post (
            string post_id,
            string token,
            string body,
            string title,
            string font = "serif",
            string lang = "en",
            bool rtl = false)
```

Returns true if the post is updated, false otherwise.

User can be anonymous if token is provided. User must be authenticated if token does not exist.

## Delete a Post

```vala
bool client.delete_post (
            string post_id,
            string token = "")
```

Returns true if the post is deleted, false otherwise.

User can be anonymous if token is provided. User must be authenticated if token does not exist.

## Claim a Post

```vala
bool client.claim_post (
            string post_id,
            string token)
```

Returns true if the post is claimed, false otherwise.

User must be logged in, and a valid token must be provided


