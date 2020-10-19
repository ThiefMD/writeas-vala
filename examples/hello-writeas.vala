public class HelloWriteas {
    public static int main (string[] args) {
        string user = "username";
        string password = "password";

        try {
            Writeas.Client client = new Writeas.Client ();
            string access_token;
            if (client.authenticate (
                    user,
                    password,
                    out access_token))
            {
                print ("Successfully logged in\n");
            } else {
                print ("Could not login");
                return 0;
            }

            string my_username;
            if (client.get_authenticated_user (out my_username)) {
                print ("Logged in as: %s\n", my_username);
            }

            string token;
            string id;
            if (client.publish_post (
                out token,
                out id,
                "Hello World!",
                "Hello Write.as!"))
            {
                print ("Made post: %s\n", id);
            }

            Writeas.Post n_post;
            if (client.get_post (out n_post, id)) {
                print ("Found post %s, %s\n", n_post.title, n_post.created);
            }

            GLib.List<Writeas.Post> posts = new GLib.List<Writeas.Post> ();
            if (client.get_user_posts (ref posts)) {
                print ("Found %u posts\n", posts.length ());
                foreach (var post in posts) {
                    print ("\t%s on %s\n", post.title, post.created);
                }
            }

            if (client.delete_post (id, token)) {
                print ("Deleted post %s\n", id);
            }

            GLib.List<Writeas.Collection> collections = new GLib.List<Writeas.Collection> ();
            if (client.get_user_collections (ref collections)) {
                print ("Found %u collections\n", collections.length ());
                foreach (var collection in collections) {
                    print ("\t%s\n", collection.title);
                }
            }

            if (client.logout ()) {
                print ("Logged out\n");
            }
        } catch (Error e) {
            warning ("Failed: %s", e.message);
        }
        return 0;
    }
}