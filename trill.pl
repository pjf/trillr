use Dancer;
use autodie;
use DBI;

use constant MAX_LENGTH => 140;

set 
    database => 'trill',
    show_errors => 1,
    template => 'template_toolkit',
    layout => 'default',
;


sub connect_db {
    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=".setting('database'),undef,undef,
        { RaiseError => 1, AutoCommit => 1 }
    );

    return $dbh;
}

sub get_trills {
    my ($user) = @_;

    my $dbh = connect_db();

    my $sth;

    if ($user) {
         $sth = $dbh->prepare(q{
            SELECT time, user, trill
            FROM trills
            WHERE user = ?
            ORDER BY time DESC
        });

        $sth->execute($user);
    }
    else {
         $sth = $dbh->prepare(q{
            SELECT time, user, trill
            FROM trills
            ORDER BY time DESC
        });

        $sth->execute;
    }

    my $trills;

    while (my ($time,$user,$trill) = $sth->fetchrow_array) {
        push @$trills, { 
            time => scalar localtime($time),
            user => $user,
            trill => $trill
        };
    }

    return $trills;

}

sub insert_trill {
    my ($name, $trill) = @_;
    my $dbh = connect_db();

    $dbh->do(
        'insert into trills (time, user, trill) values (?, ?, ?)', undef,
        time(), $name, $trill,
    );
}

get '/' => sub {
    template 'trills.tt', {
        trills => get_trills(),
        title  => 'Trillr',
    };
};

get '/:name' => sub {
    my $name = param('name');

    template 'trills.tt', {
        user   => $name,
        trills => get_trills($name),
        title  => "Trills for $name",
    };
};

post '/:name' => sub {
    my $trill = param('trill');
    my $name  = param('name');

    if (not $trill) {
        send_error("No trill supplied");
    }

    if (length($trill) > MAX_LENGTH) {
        send_error("Trill too long");
    }

    insert_trill($name,$trill);

    return forward "/$name", { trilled => 1 }, { method => 'GET' };

};

dance;
