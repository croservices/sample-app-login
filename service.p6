use Cro::HTTP::Log::File;
use Cro::HTTP::Server;
use Routes;

my Cro::Service $http = Cro::HTTP::Server.new(
    http => <1.1>,
    host => %*ENV<SAMPLE_APP_LOGIN_HOST> ||
        die("Missing SAMPLE_APP_LOGIN_HOST in environment"),
    port => %*ENV<SAMPLE_APP_LOGIN_PORT> ||
        die("Missing SAMPLE_APP_LOGIN_PORT in environment"),
    application => routes(),
    after => [
        Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
    ]
);
$http.start;
say "Listening at http://%*ENV<SAMPLE_APP_LOGIN_HOST>:%*ENV<SAMPLE_APP_LOGIN_PORT>";
react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}
