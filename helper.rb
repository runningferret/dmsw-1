#lets define some stuff

class Game
  attr_accessor :win_lose, :score, :url_num, :current_week

  def initialize(win_lose, score, url_num, current_week)
    @win_lose = win_lose
    @score = score
    @url_num = url_num
    @current_week = current_week
  end
end

def get_from_espn
  response = HTTParty.get('http://m.espn.go.com/ncf/teamschedule?teamId=127&wjb=')
  if response.code == 200
    doc = Nokogiri::HTML(response.body)
    puts "Got page okay."
  else
    raise ArgumentError, error_message(url, path)
  end

  return doc
end

def parse_games(doc, parsed_game)

  #loop through available fields that we found on the website
  doc.css('tr').each do |row|
    row.css('td.ind').each do |column|
      column.css('a').each do |game|
        if game.content.start_with?('W ', 'L ') #found a game!
	  parsed_game.current_week = parsed_game.current_week + 1
	  #split the field into the parts we need
          temp = game.content.split(' ')
          parsed_game.win_lose = temp.first
	  parsed_game.score = temp.last

          #find the espn game number to build the URL from later
          temp = game.to_s
          parsed_game.url_num = temp.match('gameId=(.*)&')[1]
        end
      #debug output
      puts game
      end
    end
  end

  #debug output
  puts parsed_game.current_week
  puts parsed_game.win_lose
  puts parsed_game.score
  puts parsed_game.url_num

  return parsed_game
end

#delete the old index file before we create the new one
def delete_index_file
  puts "Deleting old index.html file..."
  File.delete("./index.html")
end

#generate new html file from the template
def generate_html(win_lose, score, url_num)
  file = File.open("template.1", 'rb')
  html = file.read.chomp
  file.close
 
  file = File.open('template.2', 'rb')
  win_lose == "W" ? html.concat("<p class=\"yes\">Yes.") : html.concat("<p class=\"no\">No.")
  html.concat(file.read.chomp)
  file.close

  html.concat(url_num + "\" target=\"_blank\">" + score)

  file = File.open('template.3', 'rb')
  html.concat(file.read.chomp)
  file.close
  return html
end

#write the new index file that's ready for uploading
def write_index_file(html)
  index = File.open('index.html', 'w')
  index.write(html)
  index.close
  puts "Successfully created new index.html."
end

#upload the new index to the ftp
def upload_index_to_ftp
  ftp = Net::FTP.new('didmichiganstatewin.com')
  ftp.login(user=$ftp_user, passwd = $ftp_password)
  ftp.putbinaryfile('index.html')
  ftp.close
  puts "Uploaded to FTP okay!"
end

#load old index file as a string
def load_old_index
  file = File.open('index.html', 'rb')
  html = file.read.chomp
  file.close
  return html
end

#generate the new tweet
def generate_tweet(win_lose, score)
  tweet = win_lose == "W" ? "YES. " + score : "NO. " + score

  tweet.concat(". didmichiganstatewin.com")
  return tweet
end

#find the latest tweet we've posted
def load_old_tweet
  #setup twitter client
  client = Twitter::REST::Client.new do |config|
    config.consumer_key = $consumer_key
    config.consumer_secret = $consumer_secret
    config.access_token = $access_token
    config.access_token_secret = $access_token_secret
  end

  #replace t.co link with didmichiganstatewin.com so the comparison will work
  return client.user_timeline("didmsuwin").first.text.split('http').first + "didmichiganstatewin.com"
end

def tweet_new_tweet(tweet)
  #setup twitter client
  client = Twitter::REST::Client.new do |config|
    config.consumer_key = $consumer_key
    config.consumer_secret = $consumer_secret
    config.access_token = $access_token
    config.access_token_secret = $access_token_secret
  end

  puts tweet
  #client.update(tweet)
  puts "Successfully tweeted!"
end