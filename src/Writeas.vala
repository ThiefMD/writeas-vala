namespace Writeas {
    public const string RENDER_MARKDOWN = "markdown";
    public const string POST = "posts";
    public const string CLAIM_POST = "posts/claim";
    public const string COLLECTION = "collections";
    public const string LOGIN = "auth/login";
    public const string LOGOUT = "auth/me";
    public const string USER = "me";
    public const string USER_POSTS = "me/posts";
    public const string USER_COLLECTIONS = "me/collections";
    public const string USER_CHANNELS = "me/channels";

    public class Client {
        public string endpoint = "https://write.as/api/";
        private string? authenticated_user;

        public Client (string url = "") {
            if (url.chomp ().chug () != "") {
                string uri = url.chomp ().chug ();
                if (!uri.has_suffix ("/")) {
                    uri += "/";
                }
                endpoint = uri;
            }

            if (!endpoint.has_prefix ("http")) {
                endpoint = "https://" + endpoint;
            }

            authenticated_user = null;
        }

        public bool set_token (string auth_token) {
            authenticated_user = auth_token;
            string user;
            if (!get_authenticated_user (out user)) {
                authenticated_user = null;
                return false;
            }

            return true;
        }

        public bool claim_post (
            string post_id,
            string token,
            string user_token = "")
        {
            bool post_deleted = false;
            string auth_token = "";
            if (user_token == "" && authenticated_user != null) {
                auth_token = authenticated_user;
            } else {
                auth_token = user_token;
            }

            if (token == "" || auth_token == "") {
                warning ("No valid way to authenticate to update post");
                return false;
            }

            PostClaimData claim_data = new PostClaimData ();
            claim_data.token = token;
            claim_data.id = post_id;

            Json.Node root = Json.gobject_serialize (claim_data);
            Json.Generator generate = new Json.Generator ();
            generate.set_root (root);
            generate.set_pretty (false);
            string request_body = generate.to_data (null);

            WebCall claim_post = new WebCall (endpoint, CLAIM_POST);
            claim_post.set_post ();
            claim_post.set_body (request_body);
            claim_post.add_header ("Authorization", "Token %s".printf (auth_token));
            claim_post.perform_call ();

            if (claim_post.response_code == 200) {
                post_deleted = true;
            } else {
                try {
                    Json.Parser parser = new Json.Parser ();
                    parser.load_from_data (claim_post.response_str);
                    Json.Node data = parser.get_root ();
                    Response response = Json.gobject_deserialize (
                        typeof (Response),
                        data)
                        as Response;

                    if (response != null) {
                        warning ("Error: %s", response.error_msg);
                    }
                } catch (Error e) {
                    warning ("Unable to validate token: %s", e.message);
                }
            }

            return post_deleted;
        }

        public bool delete_post (
            string post_id,
            string token = "",
            string user_token = "")
        {
            bool post_deleted = false;
            string auth_token = "";
            if (user_token == "" && authenticated_user != null) {
                auth_token = authenticated_user;
            } else {
                auth_token = user_token;
            }

            if (token == "" && auth_token == "") {
                warning ("No valid way to authenticate to update post");
                return false;
            }

            PostDeleteData delete_data = new PostDeleteData ();
            delete_data.token = token;

            Json.Node root = Json.gobject_serialize (delete_data);
            Json.Generator generate = new Json.Generator ();
            generate.set_root (root);
            generate.set_pretty (false);
            string request_body = generate.to_data (null);

            WebCall delete_post = new WebCall (endpoint, POST + "/" + post_id);
            delete_post.set_delete ();
            delete_post.set_body (request_body);
            if (auth_token != "") {
                delete_post.add_header ("Authorization", "Token %s".printf (auth_token));
            }

            delete_post.perform_call ();

            if (delete_post.response_code == 204) {
                post_deleted = true;
            } else {
                try {
                    Json.Parser parser = new Json.Parser ();
                    parser.load_from_data (delete_post.response_str);
                    Json.Node data = parser.get_root ();
                    Response response = Json.gobject_deserialize (
                        typeof (Response),
                        data)
                        as Response;

                    if (response != null) {
                        warning ("Error: %s", response.error_msg);
                    }
                } catch (Error e) {
                    warning ("Unable to validate token: %s", e.message);
                }
            }

            return post_deleted;
        }

        public bool update_post (
            string post_id,
            string token,
            string body,
            string title,
            string font = "serif",
            string lang = "en",
            bool rtl = false,
            string user_token = "")
        {
            bool post_updated = false;
            string auth_token = "";
            if (user_token == "" && authenticated_user != null) {
                auth_token = authenticated_user;
            } else {
                auth_token = user_token;
            }

            if (token == "" && auth_token == "") {
                warning ("No valid way to authenticate to update post");
                return false;
            }

            PostUpdateRequestData post_update = new PostUpdateRequestData ();
            post_update.token = token;
            post_update.body = body;
            post_update.title = title;
            post_update.font = font;
            post_update.lang = lang;
            post_update.rtl = rtl;

            Json.Node root = Json.gobject_serialize (post_update);
            Json.Generator generate = new Json.Generator ();
            generate.set_root (root);
            generate.set_pretty (false);
            string request_body = generate.to_data (null);

            WebCall make_post = new WebCall (endpoint, POST + "/" + post_id);
            make_post.set_get ();
            make_post.set_body (request_body);
            if (auth_token != "") {
                make_post.add_header ("Authorization", "Token %s".printf (auth_token));
            }

            make_post.perform_call ();

            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_data (make_post.response_str);
                Json.Node data = parser.get_root ();
                PostResponse response = Json.gobject_deserialize (
                    typeof (PostResponse),
                    data)
                    as PostResponse;

                if (response != null) {
                    if (response.code == 200) {
                        post_updated = true;
                    } else {
                        warning ("Error: %s", response.error_msg);
                    }
                }
            } catch (Error e) {
                warning ("Unable to validate token: %s", e.message);
            }

            return post_updated;
        }

        public bool get_post (out Post post, string post_id)
        {
            bool post_obtained = false;
            post = null;
            if (post_id == "") {
                return false;
            }

            WebCall get_existing_post = new WebCall (endpoint, POST + "/" + post_id);
            get_existing_post.set_get ();
            get_existing_post.perform_call ();

            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_data (get_existing_post.response_str);
                Json.Node data = parser.get_root ();
                PostResponse response = Json.gobject_deserialize (
                    typeof (PostResponse),
                    data)
                    as PostResponse;

                if (response != null) {
                    if (response.code == 200) {
                        post_obtained = true;
                        post = response.data;
                    } else {
                        warning ("Error: %s", response.error_msg);
                    }
                }
            } catch (Error e) {
                warning ("Unable to validate token: %s", e.message);
            }

            return post_obtained;
        }

        public bool publish_collection_post (
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
        {
            string auth_token = "";
            token = "";
            id = "";
            bool published_post = false;
            if (user_token == "" && authenticated_user != null) {
                auth_token = authenticated_user;
            } else {
                auth_token = user_token;
            }

            if (auth_token == "") {
                warning ("User must be authenticated");
                return false;
            }

            PostRequestData new_post = new PostRequestData ();
            new_post.body = body;
            new_post.title = title;
            new_post.font = font;
            new_post.lang = lang;
            new_post.rtl = rtl;
            new_post.created = created;

            Json.Node root = Json.gobject_serialize (new_post);
            Json.Generator generate = new Json.Generator ();
            generate.set_root (root);
            generate.set_pretty (false);
            string request_body = generate.to_data (null);

            WebCall make_post = new WebCall (endpoint, COLLECTION + "/" + collection_alias + "/posts");
            make_post.set_post ();
            make_post.set_body (request_body);
            make_post.add_header ("Authorization", "Token %s".printf (auth_token));

            make_post.perform_call ();

            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_data (make_post.response_str);
                Json.Node data = parser.get_root ();
                PostResponse response = Json.gobject_deserialize (
                    typeof (PostResponse),
                    data)
                    as PostResponse;

                if (response != null) {
                    if (response.code == 201) {
                        published_post = true;
                        token = response.data.token;
                        id = response.data.id;
                    } else {
                        warning ("Error: %s", response.error_msg);
                    }
                }
            } catch (Error e) {
                warning ("Unable to publish post: %s", e.message);
            }

            return published_post;
        }

        public bool publish_post (
            out string token,
            out string id,
            string body,
            string title,
            string font = "serif",
            string lang = "en",
            bool rtl = false,
            string created = "",
            string user_token = "")
        {
            string auth_token = "";
            token = "";
            id = "";
            bool published_post = false;
            if (user_token == "" && authenticated_user != null) {
                auth_token = authenticated_user;
            } else {
                auth_token = user_token;
            }

            PostRequestData new_post = new PostRequestData ();
            new_post.body = body;
            new_post.title = title;
            new_post.font = font;
            new_post.lang = lang;
            new_post.rtl = rtl;
            new_post.created = created;

            Json.Node root = Json.gobject_serialize (new_post);
            Json.Generator generate = new Json.Generator ();
            generate.set_root (root);
            generate.set_pretty (false);
            string request_body = generate.to_data (null);

            WebCall make_post = new WebCall (endpoint, POST);
            make_post.set_post ();
            make_post.set_body (request_body);
            if (auth_token != "") {
                make_post.add_header ("Authorization", "Token %s".printf (auth_token));
            }

            make_post.perform_call ();

            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_data (make_post.response_str);
                Json.Node data = parser.get_root ();
                PostResponse response = Json.gobject_deserialize (
                    typeof (PostResponse),
                    data)
                    as PostResponse;

                if (response != null) {
                    if (response.code == 201) {
                        published_post = true;
                        token = response.data.token;
                        id = response.data.id;
                    } else {
                        warning ("Error: %s", response.error_msg);
                    }
                }
            } catch (Error e) {
                warning ("Unable to publish post: %s", e.message);
            }

            return published_post;
        }

        public bool render_markdown (out string formatted_markdown, string markdown) {
            MarkdownRequestData body_data = new MarkdownRequestData ();
            bool got_markdown = false;
            body_data.raw_body = markdown;
            formatted_markdown = "";

            WebCall render_markdown = new WebCall (endpoint, RENDER_MARKDOWN);
            render_markdown.set_post ();

            Json.Node root = Json.gobject_serialize (body_data);
            Json.Generator generate = new Json.Generator ();
            generate.set_root (root);
            generate.set_pretty (false);
            string request_body = generate.to_data (null);

            render_markdown.set_body (request_body);
            render_markdown.perform_call ();

            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_data (render_markdown.response_str);
                Json.Node data = parser.get_root ();
                MarkdownResponse response = Json.gobject_deserialize (
                    typeof (MarkdownResponse),
                    data)
                    as MarkdownResponse;

                if (response != null) {
                    if (response.code == 200) {
                        formatted_markdown = response.data.body;
                        got_markdown = true;
                    } else {
                        warning ("Error: %s", response.error_msg);
                    }
                }
            } catch (Error e) {
                warning ("Unable to get markdown: %s", e.message);
            }

            return got_markdown;
        }

        public bool get_user_collections (ref GLib.List<Collection> collections, string user_token = "") {
            string auth_token = "";
            bool got_collections = false;
            if (user_token == "" && authenticated_user != null) {
                auth_token = authenticated_user;
            } else {
                auth_token = user_token;
            }

            if (auth_token == "") {
                return false;
            }

            WebCall collection_call = new WebCall (endpoint, USER_COLLECTIONS);
            collection_call.set_get ();
            collection_call.add_header ("Authorization", "Token %s".printf (auth_token));

            bool res = collection_call.perform_call ();
            debug ("Got bytes: %d", res ? collection_call.response_str.length : 0);

            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_data (collection_call.response_str);
                Json.Node data = parser.get_root ();
                var json_obj = parser.get_root ().get_object ();
                UserCollections response = Json.gobject_deserialize (
                    typeof (UserCollections),
                    data)
                    as UserCollections;

                if (response != null) {
                    if (response.code == 200) {
                        var collection_data = json_obj.get_array_member ("data");
                        foreach (var co in collection_data.get_elements ()) {
                            var c_p = co.get_object ();
                            Collection c = new Collection ();
                            deserialize_collection (ref c, c_p);
                            collections.append (c);
                        }
                        got_collections = true;
                    } else {
                        warning ("Error: %s", response.error_msg);
                    }
                }
            } catch (Error e) {
                warning ("Unable to get user collections: %s", e.message);
            }

            return got_collections;
        }

        public bool get_user_posts (ref GLib.List<Post> posts, string user_token = "") {
            string auth_token = "";
            bool got_posts = false;
            if (user_token == "" && authenticated_user != null) {
                auth_token = authenticated_user;
            } else {
                auth_token = user_token;
            }

            if (auth_token == "") {
                return false;
            }

            WebCall post_call = new WebCall (endpoint, USER_POSTS);
            post_call.set_get ();
            post_call.add_header ("Authorization", "Token %s".printf (auth_token));

            bool res = post_call.perform_call ();
            debug ("Got bytes: %d", res ? post_call.response_str.length : 0);

            try {
                var parser = new Json.Parser ();
                parser.load_from_data (post_call.response_str);
                Json.Node data = parser.get_root ();
                var json_obj = parser.get_root ().get_object ();
                UserPosts response = Json.gobject_deserialize (
                    typeof (UserPosts),
                    data)
                    as UserPosts;

                if (response != null) {
                    if (response.code == 200) {
                        var posts_data = json_obj.get_array_member ("data");
                        foreach (var p in posts_data.get_elements ()) {
                            var ip = p.get_object ();
                            Post n_p = new Post ();
                            n_p.title = ip.has_member ("title") ? ip.get_string_member ("title") : "";
                            n_p.slug = ip.has_member ("slug") ? ip.get_string_member ("slug") : "";
                            n_p.appearance = ip.has_member ("appearance") ? ip.get_string_member ("appearance") : "";
                            n_p.language = ip.has_member ("language") ? ip.get_string_member ("language") : "";
                            n_p.rtl = ip.has_member ("rtl") ? ip.get_boolean_member ("rtl") : false;
                            n_p.created = ip.has_member ("created") ? ip.get_string_member ("created") : "";
                            n_p.updated = ip.has_member ("updated") ? ip.get_string_member ("updated") : "";
                            n_p.body = ip.has_member ("body") ? ip.get_string_member ("body") : "";
                            n_p.views = (int) (ip.has_member ("views") ? ip.get_int_member ("views") : 0);
                            n_p.token = ip.has_member ("token") ? ip.get_string_member ("token") : "";
                            n_p.tags = new string[0];
                            string[] new_tags = {};
                            if (ip.has_member ("tags")) {
                                var tags = ip.get_array_member ("tags");
                                for (int i = 0; i < tags.get_length (); i++) {
                                    new_tags += tags.get_string_element (i);
                                }
                            }
                            n_p.tags = new_tags;
                            Collection new_collection = new Collection ();
                            var c_p = ip.get_object_member ("collection");
                            if (c_p != null) {
                                deserialize_collection (ref new_collection, c_p);
                            }
                            n_p.collection = new_collection;
                            posts.append (n_p);
                        }
                        got_posts = true;
                    } else {
                        warning ("Error: %s", response.error_msg);
                    }
                }
            } catch (Error e) {
                warning ("Unable to get user posts: %s", e.message);
            }

            return got_posts;
        }

        private void deserialize_collection (ref Collection c, Json.Object c_p) {
            c.alias = c_p.has_member ("alias") ? c_p.get_string_member ("alias") : "";
            c.title = c_p.has_member ("title") ? c_p.get_string_member ("title") : "";
            c.description  = c_p.has_member ("description") ? c_p.get_string_member ("description") : "";
            c.style_sheet = c_p.has_member ("style_sheet") ? c_p.get_string_member ("style_sheet") : "";
            c.public = c_p.has_member ("public") ? c_p.get_boolean_member ("public") : false;
            c.views = (int) (c_p.has_member ("views") ? c_p.get_int_member ("views") : 0);
            c.email = c_p.has_member ("email") ? c_p.get_string_member ("email") : "";
            c.url = c_p.has_member ("url") ? c_p.get_string_member ("url") : "";
            c.monetization_pointer = c_p.has_member ("monetization_pointer") ? c_p.get_string_member ("monetization_pointer") : "";
        }

        public bool get_authenticated_user (out string username, string user_token = "") {
            username = "";
            bool logged_in = false;
            string auth_token = "";
            if (user_token == "" && authenticated_user != null) {
                auth_token = authenticated_user;
            } else {
                auth_token = user_token;
            }

            if (auth_token == "") {
                return false;
            }

            WebCall authentication = new WebCall (endpoint, USER);
            authentication.set_get ();
            authentication.add_header ("Authorization", "Token %s".printf (auth_token));

            bool res = authentication.perform_call ();
            debug ("Got bytes: %d", res ? authentication.response_str.length : 0);

            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_data (authentication.response_str);
                Json.Node data = parser.get_root ();
                MeResponse response = Json.gobject_deserialize (
                    typeof (MeResponse),
                    data)
                    as MeResponse;

                if (response != null) {
                    if (response.code == 200) {
                        logged_in = true;
                        username = response.data.username;
                    } else {
                        warning ("Error: %s", response.error_msg);
                    }
                }
            } catch (Error e) {
                warning ("Unable to validate token: %s", e.message);
            }

            return logged_in;
        }

        public bool authenticate (
            string alias,
            string password,
            out string access_token) throws GLib.Error
        {
            access_token = "";

            bool logged_in = false;
            Login login_request = new Login ();
            login_request.alias = alias;
            login_request.pass = password;

            Json.Node root = Json.gobject_serialize (login_request);
            Json.Generator generate = new Json.Generator ();
            generate.set_root (root);
            generate.set_pretty (false);
            string request_body = generate.to_data (null);

            WebCall authentication = new WebCall (endpoint, LOGIN);
            authentication.set_body (request_body);
            authentication.set_post ();
            bool res = authentication.perform_call ();
            debug ("Got bytes: %d", res ? authentication.response_str.length : 0);

            Json.Parser parser = new Json.Parser ();
            parser.load_from_data (authentication.response_str);
            Json.Node data = parser.get_root ();
            LoginResponse response = Json.gobject_deserialize (
                typeof (LoginResponse),
                data)
                as LoginResponse;

            if (response != null) {
                if (response.code == 200) {
                    logged_in = true;
                    access_token = response.data.access_token;
                    authenticated_user = response.data.access_token;
                } else {
                    warning ("Error: %s", response.error_msg);
                }
            }

            return logged_in;
        }

        public bool logout (string user_token = "") {
            string auth_token = "";
            if (user_token == "" && authenticated_user != null) {
                auth_token = authenticated_user;
            } else {
                auth_token = user_token;
            }

            if (auth_token == "") {
                return false;
            }

            WebCall authentication = new WebCall (endpoint, LOGOUT);
            authentication.set_delete ();
            authentication.add_header ("Authorization", "Token %s".printf (auth_token));

            bool res = authentication.perform_call ();
            debug ("Got bytes: %d", res ? authentication.response_str.length : 0);

            if (authentication.response_code != 204) {
                try {
                    Json.Parser parser = new Json.Parser ();
                    parser.load_from_data (authentication.response_str);
                    Json.Node data = parser.get_root ();
                    Response response = Json.gobject_deserialize (
                        typeof (Response),
                        data)
                        as Response;

                    warning ("Unable to logout: %s", response.error_msg);
                } catch (Error e) {
                    warning ("Unable to logout: %s", e.message);
                }
                return false;
            }

            authenticated_user = null;
            return true;
        }
    }

    public class Response : GLib.Object, Json.Serializable {
        public int code { get; set; }
        public string error_msg { get; set; }
    }

    public class PostResponse : Response {
        public Post data { get; set; }
    }

    public class MarkdownResponse : Response {
        public MarkdownData data { get; set; }
    }

    public class MarkdownData : GLib.Object, Json.Serializable {
        public string body { get; set; }
    }

    public class UserPosts : Response {
        public Post[] data { get; set; }
    }

    public class UserCollections : Response {
        public Collection[] data { get; set; }
    }

    public class Post : GLib.Object, Json.Serializable {
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
        public Collection collection { get; set; }
        public string token { get; set; }
    }

    public class Collection : GLib.Object, Json.Serializable {
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

    public class MeResponse : Response {
        public MeData data { get; set; }
    }

    public class MeData : GLib.Object, Json.Serializable {
        public string username { get; set; }
    }

    private class Login : GLib.Object, Json.Serializable {
        public string alias { get; set; }
        public string pass { get; set; }
    }

    public class LoginResponse : Response {
        public LoginData data { get; set; }
    }

    private class PostClaimData : GLib.Object, Json.Serializable {
        public string token { get; set; }
        public string id { get; set; }
    }

    private class PostDeleteData : GLib.Object, Json.Serializable {
        public string token { get; set; }
    }

    private class PostRequestData : GLib.Object, Json.Serializable {
        public string body { get; set; }
        public string title { get; set; }
        public string font { get; set; }
        public string lang { get; set; }
        public bool rtl { get; set; }
        public string created { get; set; }
    }

    private class PostUpdateRequestData : GLib.Object, Json.Serializable {
        public string token { get; set; }
        public string body { get; set; }
        public string title { get; set; }
        public string font { get; set; }
        public string lang { get; set; }
        public bool rtl { get; set; }
    }

    private class MarkdownRequestData : GLib.Object, Json.Serializable {
        public string raw_body { get; set; }
    }

    public class LoginData : GLib.Object, Json.Serializable {
        public string access_token { get; set; }
        public UserData user { get; set; }
    }

    public class UserData : GLib.Object, Json.Serializable {
        public string username { get; set; }
        public string email { get; set; }
        public string created { get; set; }
    }

    private class WebCall {
        private Soup.Session session;
        private Soup.Message message;
        private string url;
        private string body;

        public string response_str;
        public uint response_code;

        public class WebCall (string endpoint, string api) {
            url = endpoint + api;
            session = new Soup.Session ();
            body = "";
        }

        public void set_body (string data) {
            body = data;
        }

        public void set_get () {
            message = new Soup.Message ("GET", url);
        }
        
        public void set_put () {
            message = new Soup.Message ("PUT", url);
        }

        public void set_delete () {
            message = new Soup.Message ("DELETE", url);
        }

        public void set_post () {
            message = new Soup.Message ("POST", url);
        }

        public void add_header (string key, string value) {
            message.request_headers.append (key, value);
        }

        public bool perform_call () {
            bool success = false;
            debug ("Calling %s", url);

            if (body != "") {
                message.set_request ("application/json", Soup.MemoryUse.COPY, body.data);
            } else {
                add_header ("Content-Type", "application/json");
            }

            session.send_message (message);
            response_str = (string) message.response_body.flatten ().data;
            response_code = message.status_code;

            if (response_str != null && response_str != "") {
                success = true;
                debug ("Non-empty body");
            }

            if (response_code >= 200 && response_code <= 250) {
                success = true;
                debug ("Success HTTP code");
            }

            return success;
        }
    }
}