use Dancer;
use autodie;
use DBI;

use constant MAX_LENGTH => 140;

set 
    database => 'trill',
    show_errors => 1,
    template => 'template_toolkit',
;


sub connect_db {
    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=".setting('database'),undef,undef,
        { RaiseError => 1, AutoCommit => 1 }
    );

    return $dbh;
}

get '/' => sub {
    my $dbh = connect_db();
    my $sth = $dbh->prepare('select time,user,trill from trills order by time desc');
    $sth->execute();

    my $trills;

    while (my ($time,$user,$trill) = $sth->fetchrow_array) {
        push @$trills, { 
            time => scalar localtime($time),
            user => $user,
            trill => $trill
        };
    }

    template 'trills.tt', {
        trills => $trills
    };
};

get '/user/:name' => sub {
    my $name = param('name');
    my $dbh  = connect_db();

    my $sth = $dbh->prepare('select time,user,trill from trills where user = ? order by time desc');
    $sth->execute($name);

    my $trills;

    while (my ($time,$user,$trill) = $sth->fetchrow_array) {
        push @$trills, { 
            time => scalar localtime($time),
            user => $user,
            trill => $trill
        };
    }

    template 'trills.tt', {
        user   => $name,
        trills => $trills
    };
};

post '/user/:name' => sub {
    my $trill = param('trill');
    my $name  = param('name');

    if (not $trill) {
        send_error("No trill supplied");
    }

    if (length($trill) > MAX_LENGTH) {
        send_error("Trill too long");
    }

    my $dbh = connect_db();

    $dbh->do(
        'insert into trills (time, user, trill) values (?, ?, ?)', undef,
        time(), $name, $trill,
    );

    return forward "/user/$name", { trilled => 1 }, { method => 'GET' };

};

dance;
