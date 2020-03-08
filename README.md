sinatra\_blogomatic
===================

Ruby Sinatra application for hosting a few Gmail API endpoints.

This commit adds Gmail API support for
using email as a work queue. A specific
email query will be automatically saved
onto the local file system for other utilities
to discover and work upon.

The main goal of this was to be able to
email a blog article so that some other script
can pick it up later, say in a cron entry.

Emails with attachments are minimally supported, so long
as their original authoring software was one of gmail,
outlook express 2016 mac, or the outlook owa web client. None
of these are being tracked for changes, you're on your own.

Emails with image attachments will be converted from the
email content-id src img format into a web format, so long
as again, they are from the above list of email clients. There
does not seem to be a standard way of encoding the original
email filename, so it's a treasure hunt to find them.

You could write a little script to shovel them into a static
S3 blog, or any other post processing you can think of.

Additionally, there is a little support for other commands,
but only as a bit of a scaffolding right now. I might add
support for this but I am making zero promises about anything.

Mostly I am sharing this code because the gmail API is largely
undocumented in the way of examples. I fully disclaim that
my code is idiomatic, and you should not copy any of the code
in this repo as a source for learning. There are far smarter people
sharing their code for that.

Good luck!

Helpful articles about JSON Web Token and ruby:

http://www.intridea.com/blog/2013/11/7/json-web-token-the-useful-little-standard-you-haven-t-heard-about

Built using:

[Sinatra](http://www.sinatrarb.com)

[ruby-jwt](https://github.com/progrium/ruby-jwt)

To get started with this project
=================================

Clone this repo and run bundle

To start the sinatra server:

from sinatra\_blogomatic/

First run `bundle` to get your gems all satisfied, and then

`bundle exec ruby app.rb`

You should see sinatra fire up with Webrick.  Point your web browser to:

http://localhost:8080/

There is some original JWT code from the repo this project was forked from, but the
operative APIs are /gmail to automatically log into gmail and download relevant messages,
and then /jobs to process the downloaded work directories.

Thats it, there's no reason for this to be a sinatra application, but you could easily
convert the job results into something that Sinatra serves back to the web. I just like
having little api endpoints so I can invoke the jobs with curl from other systems.

This app will load app.rsa and app.rsa.pub as sign and verify keys for the JWT encode and decode

the app.rsa and app.rsa.pub were generated with:

`openssl genrsa -out keys/app.rsa 2048`

`openssl rsa -in keys/app.rsa -pubout > keys/app.rsa.pub`
