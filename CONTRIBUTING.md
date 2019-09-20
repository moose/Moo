# Contributing

Thank you for considering contributing to this distribution.  This file
contains instructions that will help you work with the source code.

## Contact

If you have any issues or questions, you can reach out to the other developers
in a number of ways:

 * IRC : [#moose on irc.perl.org](https://kiwiirc.com/nextclient/#irc://irc.perl.org/#moose)
 * RT (web) : [Moo on rt.cpan.org](https://rt.cpan.org/Public/Dist/Display.html?Name=Moo)
 * RT (email) : [Moo at rt.cpan.org](mailto:bug-Moo@rt.cpan.org)

## Testing

For testing as a contributor, you can run:

    perl Makefile.PL
    make
    make test

It is also be possible to run the tests directly without building:

    prove -lvr t xt

or

    perl -Ilib t/moo-accessors.t

To run the full test suite, developer prereqs should be installed.  This can
be done using cpanm:

    cpanm --installdeps --with-recommends --with-develop .

## Pull Requests

Pull requests to for this distribution can be submitted on [GitHub](https://github.com/moose/Moo).
Additional help with submitting pull requests can be found on [GitHub Help](https://help.github.com/articles/creating-a-pull-request).

Patches can also be sent as RT tickets via the [web interface](https://rt.cpan.org/Public/Dist/Display.html?Name=Moo)
or through [email](mailto:bug-Moo@rt.cpan.org).

## Continuous Integration

All code pushed to a branch or submitted as a pull request will automatically
be tested on Travis-CI across all versions of perl supported by Moo.

The results of the test runs for pull requests can be viewed at [here](https://travis-ci.com/github/moose/Moo/pull_requests).

## Coverage

Moo tries to maintain very high test coverage (100% statement and branch
coverage).  Ideally, pull requests should include new tests to prove the new
feature or bug fix.  However, submitting a pull request or patch without
tests would still be better than not submitting a valuable change at all.

Coverage metrics from Travis-CI runs can be viewed [here](https://codecov.io/gh/moose/Moo).

## Releasing

The distribution is managed with [Distar](https://github.com/p5sagit/Distar).
It uses a standard ExtUtils::MakeMaker workflow, but with extra sanity checks
for releasing.  Most contributors do not need to be concerned with this, but
if desired, extra testing can be performed with:

    make releasetest

The normal release process would be:

    make bump         # bump version.  alternatively, bumpminor or bumpmajor.
    make nextrelease  # add version heading to Changes file
    make release      # test and release

This process can be tested using the `FAKE_RELEASE` option:

    make release FAKE_RELEASE=1

Note that a fake release will still create a git commit, tag, and a release
tarball.  But it will not upload or push anything.
