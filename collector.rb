require 'rubygems'
require 'json/pure'
require 'xmpp4r'
require 'xmpp4r/roster'

class Collector
  include Jabber
  attr_accessor :jid, :password, :options, :counts, :images, :hashtag
  attr_reader :client, :roster

  def initialize
    self.jid = "collector@jabber.notu.be"
    self.password = "foobar"
    @client = Client.new(self.jid)
    self.options = []
    self.hashtag = ""
    self.counts ={ "Joyce"=> 9, "John"=> 1, "Giles"=> 0, "Grace"=> 1, "Teddy Molloy"=> 0, "Iris"=> 0, "Ronnie"=> 0, "Tom"=> 6, "Libby"=> 1, "Sebastian"=> 0, "Ken"=> 0, "Frank"=> 0, "Camilla"=> 1, "Gerald"=> 6 }
    self.images={ "Joyce"=> "http://dev.notu.be/2010/10/mm/images/joyce.jpg", "Giles"=> "http://www.macfarlane-chard.co.uk/files/clients/BonesKen.jpg", "Tom Seleck"=> "http://tomselleck.tv-website.com/images/pic_selleck.jpg", "Grace"=> "http://www.bbc.co.uk/pressoffice/images/bank/programmes_tv/drama/sinchronicity/300camille.jpg", "Posh Man"=> "http://dev.notu.be/2010/10/mm/images/unknown_man_1.gif", "Iris"=> "http://media.ove.cybermage.se/2010/03/Michelle-Fairley-2.jpg", "Teddy Molloy"=> "http://static.episode39.it/artist/3224.jpg", "Tom"=> "http://dev.notu.be/2010/10/mm/images/barnaby.jpg", "Libby"=> "http://thm-a01.yimg.com/nimage/6f3f771a10cf63fa", "Ken"=> "http://www.carrieswar.com/images/Daniel.jpg", "Camilla"=> "http://www.radiotimes.com/shows/torchwood/cast/daniela-denby-ashe%20/img.jpg", "Gerald"=> "http://3.bp.blogspot.com/_RaOrchOImw8/StdrWx0iicI/AAAAAAAAZys/cq-wNz3RufU/s400/Kevin+R+McNally.jpg", "Frank"=> "http://radaris.com/imdb/8/1/8156ed21c571b627e129f93718abe98f.jpg" }
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

    #the "roster" is our bot contact list
    @roster = Roster::Helper.new(@client)

    #start_presence_callback
    start_subscription_request_callback

    #...to do something with the messages we receive
    start_message_callback

    # doesn't do anything useful as yet
    #start_presence_sending

  end

  def start_message_callback
    @client.add_message_callback do |msg|
      if(msg.body.match("do_hello"))
        jid = msg.from
        status = "{'counts':"+JSON.pretty_generate(counts)+",'images':"+JSON.pretty_generate(images)+",'hashtag':'"+self.hashtag+"'}"
        new_msg = Message::new(jid,status)
        new_msg.type=:chat
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
        # give back the totals
        fr_jid = msg.from
        status = "{'counts':"+JSON.pretty_generate(counts)+",'images':"+JSON.pretty_generate(images)+",'hashtag':'"+self.hashtag+"'}"
        new_msg = Message::new(fr_jid,status)
        new_msg.type=:chat
        @client.send(new_msg)
      end

      if(msg.body.match("do_refresh"))
        puts "sending refresh response #{msg.from}"
        # give back the totals
        fr_jid = msg.from
        status = "{'counts':"+JSON.pretty_generate(counts)+",'images':"+JSON.pretty_generate(images)+",'hashtag':'"+self.hashtag+"'}"
        new_msg = Message::new(fr_jid,status)
        new_msg.type=:chat
        @client.send(new_msg)
      end

###admin stuff
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
           puts "count is #{counts[bn]} #{options.size}"
           fr_jid = msg.from
           status = "{'counts':"+JSON.pretty_generate(counts)+",'images':"+JSON.pretty_generate(images)+",'hashtag':'"+self.hashtag+"'}"
           new_msg = Message::new(fr_jid,status)
           new_msg.type=:chat
           @client.send(new_msg)
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

    end

  end

  def start_presence_sending
    @roster.wait_for_roster
    t1 = Thread.new do
      count = 0
      while(true)
        count = count +1
        sleep(10)
        status = "{'counts':"+JSON.pretty_generate(counts)+",'images':"+JSON.pretty_generate(images)+",'hashtag':"+self.hashtag+"}"
        p = Jabber::Presence.new(:chat,status).set_type(:available)
        @client.send(p)
      end
    end
  end

  def start_presence_callback
    @roster.add_presence_callback do |item,pres|
      puts "pres!!!!!!! #{pres}"
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

