   require 'rubygems'
   require 'xmpp4r'
   require 'xmpp4r/roster'
   require 'hpricot'
   require 'webrick'
   require 'webrick/accesslog'
   include WEBrick

   class CreateJID < HTTPServlet::AbstractServlet
      include Jabber

      attr_reader :client, :roster
      attr_accessor :jid, :password

      def do_POST(req, res)
       begin
         # this is the cookie twitetr gives oyu when successfully connected
         cookie = req.query["cookie"]
         if(cookie && cookie!="")

           #passing in the cookie - probably wrong but it's not a page 
           #that's called directly, but very jquery

           cookie = cookie.to_s
           arr = cookie.split(":")
           user_id = arr[0]
           consumer_secret="3IGL..." #from Twitter

           #confirm that it's a real cookie from twitter
           re = Digest::SHA1.hexdigest(user_id + consumer_secret)
           if(re==arr[1])
             # ths is the twitter user id
             un = arr[0]
#            un = rand(1000000) ##for testing, generate a new sccount each time
             un = un.to_s
             # not super high security this
             self.password=un

             puts "trying to register #{un}@jabber.notu.be"
             self.jid  = "#{un}@jabber.notu.be"

             # catch any failures / duplicates
             Jabber::debug = true
             @client = Client.new(self.jid)
             @client.connect

             begin
               begin
                 @client.register(password)
                 @client.close
                 #with xmpp4r you have to login again or it throws a roster error
                 @client.connect
               rescue
                 puts "already registered"
               end

               @client.auth(self.password)

               # send a subscripton request to the collector
               @accept_subscriptions = true
               @client.send(Presence.new.set_type(:available))
               @roster = Roster::Helper.new(@client)
               coll = "collector@jabber.notu.be"
               @roster.add(coll,nil,true)

               res.status = 201
               res.body=jid

               #close it - control now passes to the strophe client side
               @client.close

             rescue Jabber::ServerError=>e
               puts e
               if e.to_s.match(/conflict/)
                 res.status = 200
                 res.body=jid
               else
                 res.status = 401
                 res.body=jid
               end
             end
             res['Content-Type'] = 'text/javascript'
           else
             res.body='Authentication failed'
             res.status = 401
           end
         else
           res.body='No username provided'
           res.status = 400
         end
       rescue Exception=>e
          res.status = 500
          res.body='Server Error'
          puts e.inspect
          puts e.backtrace
       end

      end

      # cf. http://www.hiveminds.co.uk/node/244, published under the
      # GNU Free Documentation License, http://www.gnu.org/copyleft/fdl.html

      @@instance = nil
      @@instance_creation_mutex = Mutex.new

   end


