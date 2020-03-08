sinatra\_blogomatic


===================

Elevator Pitch: Modern email editors are 80% of what you need 
to edit the HTML of a website. Mobile phones, corporate work email,
web email, are all basically good enough to write a simple webpage
with basic formatting and inline images. What if we just considered
those clients to be 'good enough' and relied on them as authoring
tools for pet websites? I can easily write a post from my phone
including a few photos, of my latest woodworking projects, and
I can take a lunch break to muse on the latest current events.

Emailing myself a rich email is easy to automatically download
using the Gmail API, and then converting it into a webpage for
publishing. This project gets you about 60% of the way there.

It's MVP, it's untested, it's got tons of other bits that are not
relevant. This is not here to be a resume booster. It's here
to share some ruby gmail api code, because it was a bit of a pain
to figure it out.

Please read the commit log for some caveats.

===================


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
