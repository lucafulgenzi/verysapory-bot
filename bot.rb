require 'telegram/bot'
require 'mongo'
require 'date'

token = '1639209495:AAEXRblkcF1R8ByYZVutxgFh2yVz0wLCO08'  #Telegram Token
admin_id = '229173366'  #luca_fulgenzi ID
piatti = ['Calzone Salame e Ricotta', 'Calzone Patate e Salsicca', 'Panino wustel e patatine']
prezzi = [1.5, 1.5, 1]
ordinazione = Array.new
totale = 0

Mongo::Logger.logger.level = ::Logger::FATAL
client = Mongo::Client.new('mongodb+srv://admin:admin@cluster0.rhtp2.mongodb.net/telegram-bot?retryWrites=true&w=majority')


kb = [
  Telegram::Bot::Types::KeyboardButton.new(text: piatti[0] + ' $' + prezzi[0].to_s ),
  Telegram::Bot::Types::KeyboardButton.new(text: piatti[1] + ' $' + prezzi[1].to_s),
  Telegram::Bot::Types::KeyboardButton.new(text: piatti[2] + ' $' + prezzi[2].to_s)
]

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Bot per l'ordinazione a VerySapory.🐖 ")
    when '/ordina'
      

      ordinazione.clear()
      totale = 0
      question = 'Scegli i piatti'
      markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)
      bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: markup)       
    when '/riepilogo'
      if(ordinazione.length != 0)
        bot.api.send_message(chat_id: message.chat.id, text: "Riepilogo oridne:")
        ordinazione.each do |piatto_ordinazione|
          bot.api.send_message(chat_id: message.chat.id, text: piatto_ordinazione)  
        end
        bot.api.send_message(chat_id: message.chat.id, text: 'Totale $ ' + totale.to_s) 
      else
        bot.api.send_message(chat_id: message.chat.id,text: "Il tuo ordine é vuoto!")
      end
    when '/conferma'
      if(ordinazione.length != 0)
        order_date = Time.new
        bot.api.send_message(chat_id: message.chat.id, text: "Ordine inviato al server. Riepilogo:")
        ordinazione.each do |piatto_ordinazione|
          bot.api.send_message(chat_id: message.chat.id, text: piatto_ordinazione)  
          order_doc = { :_id => BSON::ObjectId.new, :user => message.chat.username, :date => order_date.strftime("%Y-%m-%d"), :piatto => piatto_ordinazione}
          client[:orders].insert_one order_doc
        end
        bot.api.send_message(chat_id: message.chat.id, text: 'Totale $ ' + totale.to_s) 
        user_doc = { :_id => BSON::ObjectId.new, :user => message.chat.username, :date => order_date.strftime("%Y-%m-%d"), :totale => totale.to_s}
        client[:user].insert_one user_doc
        
      else
        bot.api.send_message(chat_id: message.chat.id,text: "Il tuo ordine é vuoto!")
      end
    when '/ordinegiorno'
      order_date = Time.new
      ordine_oggi = Array.new 
      client[:orders].find({"date" => order_date.strftime("%Y-%m-%d")}, { :projection => {:_id => 0, :date => 0} }).each do |doc|
        ordine_oggi.push(doc)  
      end
      ordine_oggi.each do |ordinazione_oggi|
        bot.api.send_message(chat_id: message.chat.id,text: "@#{ordinazione_oggi.values.first}: #{ordinazione_oggi.values.last}")
      end
    when '/totalegiorno'
      order_date = Time.new
      totale_persona_oggi = Array.new 
      totale_ordini_oggi = 0
      client[:user].find({"date" => order_date.strftime("%Y-%m-%d")}, { :projection => {:_id => 0, :date => 0} }).each do |doc|
        totale_persona_oggi.push(doc)  
      end
      totale_persona_oggi.each do |totale_oggi|
        bot.api.send_message(chat_id: message.chat.id,text: "@#{totale_oggi.values.first}: $#{totale_oggi.values.last}")
        totale_ordini_oggi += totale_oggi.values.last.to_f
      end 
      bot.api.send_message(chat_id: message.chat.id,text: "Totale: $ #{totale_ordini_oggi}")
    when piatti[0] + ' $' + prezzi[0].to_s
      ordinazione.push(piatti[0])
      totale += prezzi[0]
    when piatti[1] + ' $' + prezzi[1].to_s
      ordinazione.push(piatti[1])
      totale += prezzi[1] 
    when piatti[2] + ' $' + prezzi[2].to_s
      ordinazione.push(piatti[2])
      totale += prezzi[2]  
    else
      bot.api.send_message(chat_id: message.chat.id,text: "Comando non esistente!")
    end
  end
  client.close
end
