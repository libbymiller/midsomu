require 'rubygems'
require 'json/pure'
require 'xmpp4r'
require 'xmpp4r/roster'

class Collector
  include Jabber
  attr_accessor :jid, :password, :options, :counts, :images, :hashtag
  attr_reader :client, :roster

  def initialize
    self.jid = "collector6@jabber.notu.be"
    self.password = "foobar"
    @client = Client.new(self.jid)
    self.options = ['Joyce','Tom','Posh Man']
    self.hashtag = ""
    self.options.each do |o|
      self.counts[o]=0
    end
    Jabber::debug = true
    connect
  end

  def connect
    @client.connect
    @accept_subscriptions = true
    @client.auth(@password)
    @client.send(Presence.new.set_type(:available))

    @roster = Roster::Helper.new(@client)

    start_subscription_request_callback

    start_message_callback

  end

  def start_message_callback
    @client.add_message_callback do |msg|
      if(msg.body.match("do_hello"))
        jid = msg.from
        status = "{'counts':"+JSON.pretty_generate(counts)+",'images':"+JSON.pretty_generate(images)+",'hashtag':'"+self.hashtag+"'}"
        new_msg = Message::new(jid,status)
        new_msg.type=:chat
        # just this one time we do a chat, therest of teh time we waity for presence
        # this is because it takes  little while to sort itself out it seems, the first time
        @client.send(new_msg)
      end
      if(msg.body.match("do_vote"))
        puts "sending vote response #{msg.from}"
        # increment the counts
        puts msg.body
        r = JSON.parse(msg.body)
        b = r["do_vote"]
        c = counts[b]
        puts "got a count for #{b} which is #{c}"        
        d = c+1
        counts[b]=d
      end

# admin options
      if(msg.body.match("do_add_option"))
         puts "adding option"
         r = JSON.parse(msg.body)
         b = r["do_add_option"]
         bn = b["name"]
         if(bn)
           puts "got option #{bn}"
           self.options.push(bn) #should be more complex
           self.counts[bn]=0
           ii = b["image"]
           if(ii)
             self.images[bn]=ii
           end
         else
           puts "no name found"
         end
      end

      if(msg.body.match("do_remove_option"))
         # not yet implemented
         puts "removing option"
         r = JSON.parse(msg.body)
         b = r["do_remove_option"]
         self.options.delete(b)
         self.counts.delete(b)
      end
      if(msg.body.match("do_set_hashtag"))
         puts "setting hash tag"
         r = JSON.parse(msg.body)
         b = r["do_set_hashtag"]
         self.hashtag = b
      end
      # update presence for everything and everyone (tooo much?)

      status = "{'counts':"+JSON.pretty_generate(counts)+",'images':"+JSON.pretty_generate(images)+",'hashtag':'"+self.hashtag+"'}"
      p = Jabber::Presence.new(:chat,status).set_type(:available)
      @client.send(p)
    end

  end

  def start_subscription_request_callback
    @roster.add_subscription_request_callback do |item,presence|
      @roster.accept_subscription(presence.from)
    end
  end


end

Collector.new
Thread.stop

