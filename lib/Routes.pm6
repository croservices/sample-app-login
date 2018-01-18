use Cro::HTTP::Auth;
use Cro::HTTP::Session::InMemory;
use Cro::HTTP::Router;

class UserSession does Cro::HTTP::Auth {
    has $.username is rw;

    method logged-in() {
        defined $!username;
    }
}

my $routes = route {
    subset LoggedIn of UserSession where *.logged-in;

    get -> UserSession $s {
        if $s.logged-in {
            content 'text/html', q:c:to/HTML/;
            Current user's name: {$s.username}
            See your <a href="/users-only">secret page</a>.
            <form method="post" action="/logout">
                <input type="submit" value="Log out" />
            </form>
            HTML
        } else {
            content 'text/html', q:to/HTML/;
            No user logged!
            <form action="/login">
                <input type="submit" value="Log in" />
            </form>
            HTML
        }
    }

    get -> LoggedIn $user, 'users-only' {
        content 'text/html', "Secret page just for *YOU*, {$user.username()}; <a href=\"/\">Go back</a>.";
        
    }
    get -> UserSession $user, 'users-only' {
        redirect '/', :see-other;
    }

    get -> UserSession $user, 'login' {
        content 'text/html', q:to/HTML/;
            <form method="POST" action="/login">
              <div>
                Username: <input type="text" name="username" />
              </div>
              <div>
                Password: <input type="password" name="password" />
              </div>
              <input type="submit" value="Log In" />
            </form>
            HTML
    }

    post -> UserSession $user, 'login' {
        request-body -> (:$username, :$password, *%) {
            if valid-user-pass($username, $password) {
                $user.username = $username;
                redirect '/', :see-other;
            }
            else {
                content 'text/html', "Bad username/password";
            }
        }
    }

    post -> UserSession $user, 'logout' {
        $user.username = Nil;
        redirect '/', :see-other;
    }

    sub valid-user-pass($username, $password) {
        # Call a database or similar here
        $username eq 'user1' && $password eq 'password1' ||
        $username eq 'user2' && $password eq 'password2';
    }
}

sub routes() is export {
    route {
        # Apply middleware, then delegate to the routes.
        before Cro::HTTP::Session::InMemory[UserSession].new;
        delegate <*> => $routes;
    }
}
