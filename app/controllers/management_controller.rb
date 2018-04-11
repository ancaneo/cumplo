class ManagementController < ApplicationController
  require 'net/https'
  def index
    key = '2a5021c7a07c2b712032c0c5d63e42a732bd5b40'
    @start_date = params[:start]
    @finish_date = params[:finish]
    @ufData = []
    @dollarData = []
    @nationalShortLow = [] #Tipos: 1, 2, 10, 26
    @nationalShortHigh = [] #Tipos: 1, 2, 11, 25
    @nationalLongVeryLow = [] #Tipos: 1, 3, 4, 7, 30, 33, 45
    @nationalLongLow = [] #Tipos: 1, 3, 5, 7, 30, 33, 44
    @nationalLongHigh = [] #Tipos: 1, 3, 6, 8, 27, 35
    @nationalLongVeryHigh = [] #Tipos: 1, 3, 6, 9, 29, 34
    @nationalChangeShort = [] #Tipos: 12, 21, 40
    @nationalChangeLongLow = [] #Tipos: 20, 23, 24, 40
    @nationalChangeLongHigh = [] #Tipos: 20, 22, 23, 40 
    @foreignLowTcm = [] #Tipos: 15, 36, 38, 41
    @foreignHighTcm = [] #Tipos: 15, 36, 38, 42
    @otherTcm = [] #Tipos: 43
    @days=[]
    if params[:start].present? && params[:finish].present?
      start = params[:start].gsub('-','/')
      finish = params[:finish].gsub('-','/')
      # Hay un error en la api respecto a las consultas por día. Entonces se realiza la consulta por mes
      if start <= finish
        #El dólar no se define sábados y domingos, por lo que se requiere ver hasta 2 días antes
        dollarStart = (Date.parse(start) - 2.days).to_s.gsub('-','/')
        # TCM se define de acuerdo a su último registro
        tcmStart = (Date.parse(start) - 1.month).to_s.gsub('-','/')
        p "https://api.sbif.cl/api-sbifv3/recursos_api/dolar/periodo/#{start[0,7]}/#{finish[0,7]}?apikey=#{key}&formato=json"
        ufUri = URI("https://api.sbif.cl/api-sbifv3/recursos_api/uf/periodo/#{start[0,7]}/#{finish[0,7]}?apikey=#{key}&formato=json")
        dollarUri = URI("https://api.sbif.cl/api-sbifv3/recursos_api/dolar/periodo/#{dollarStart[0,7]}/#{finish[0,7]}?apikey=#{key}&formato=json")
        tmcUri = URI("https://api.sbif.cl/api-sbifv3/recursos_api/tmc/periodo/#{tcmStart[0,7]}/#{finish[0,7]}?apikey=#{key}&formato=json")
        ufResponse = Net::HTTP.get(ufUri)
        dollarResponse = Net::HTTP.get(dollarUri)
        tmcResponse = Net::HTTP.get(tmcUri)
        ufData = eval(ufResponse)[:UFs]
        dollarData = eval(dollarResponse)[:Dolares]
        tmcData = eval(tmcResponse.gsub('null','nil'))[:TMCs]
        day = Date.parse(start)
        finish_date = Date.parse(finish)
        index_uf = 0
        index_dollar = 0
        index_tmc = 0
        @count = 0
        @ufChart = {}
        @dollarChart = {}
        @tmcChart = [
          {name: "Operaciones no reajustables, CLP, <= 90 días, <= 5.000 UF", data: {}},
          {name: "Operaciones no reajustables, CLP, <= 90 días, > 5.000 UF", data: {}},
          {name: "Operaciones no reajustables, CLP, > 90 días, <= 50 UF", data: {}},
          {name: "Operaciones no reajustables, CLP, > 90 días, > 50 UF, <= 200 UF", data: {}},
          {name: "Operaciones no reajustables, CLP, > 90 días, > 200 UF, <= 5000 UF", data: {}},
          {name: "Operaciones no reajustables, CLP, > 90 días, > 5000 UF", data: {}},
          {name: "Operaciones reajustables, CLP, < 1 año", data: {}},
          {name: "Operaciones reajustables, CLP, >= 1 año, <= 2000 UF", data: {}},
          {name: "Operaciones reajustables, CLP, >= 1 año, > 2000 UF", data: {}},
          {name: "Operaciones reajustables, moneda extranjera, <= 2000 UF", data: {}},
          {name: "Operaciones reajustables, moneda extranjera, > 2000 UF", data: {}},
          {name: "Otras, > 2000 UF", data: {}},
        ]
        while day <= finish_date do
          while ufData && ufData[index_uf + 1] && Date.parse(ufData[index_uf + 1][:Fecha]) <= day do
            index_uf += 1
          end
          @ufData << ufData[index_uf][:Valor].gsub('.','').gsub(',','.').to_f
          while dollarData && dollarData[index_dollar + 1] && Date.parse(dollarData[index_dollar + 1][:Fecha]) <= day do
            index_dollar += 1
          end
          @dollarData << dollarData[index_dollar][:Valor].gsub(',','.').to_f
          while tmcData && tmcData[index_tmc + 1] && Date.parse(tmcData[index_tmc + 1][:Fecha]) <= day do
            index_tmc += 1
          end
          
          nationalShortLowObj = tmcData[0..index_tmc].reverse.find{|object| object[:Tipo] === "1"|| object[:Tipo] === "2"|| object[:Tipo] === "10" || object[:Tipo] === "26"}
          @nationalShortLow << (nationalShortLowObj ? nationalShortLowObj[:Valor].to_f : nil)
          nationalShortHighObj = tmcData[0..index_tmc].reverse.find{|object| object[:Tipo] === "1"|| object[:Tipo] === "2"|| object[:Tipo] === "11" || object[:Tipo] === "25"}
          @nationalShortHigh << (nationalShortHighObj ? nationalShortHighObj[:Valor].to_f : nil)
          nationalLongVeryLowObj = tmcData[0..index_tmc].reverse.find{|object| object[:Tipo] === "1"|| object[:Tipo] === "3"|| object[:Tipo] === "4"|| object[:Tipo] === "7 "|| object[:Tipo] === "30" || object[:Tipo] === "33" || object[:Tipo] === "45"}
          @nationalLongVeryLow << (nationalLongVeryLowObj ? nationalLongVeryLowObj[:Valor].to_f : nil)
          nationalLongLowObj = tmcData[0..index_tmc].reverse.find{|object| object[:Tipo] === "1"|| object[:Tipo] === "3"|| object[:Tipo] === "5"|| object[:Tipo] === "7 "|| object[:Tipo] === "30" || object[:Tipo] === "33" || object[:Tipo] === "44"}
          @nationalLongLow << (nationalLongLowObj ? nationalLongLowObj[:Valor].to_f : nil)
          nationalLongHighObj = tmcData[0..index_tmc].reverse.find{|object| object[:Tipo] === "1"|| object[:Tipo] === "3"|| object[:Tipo] === "6"|| object[:Tipo] === "8 "|| object[:Tipo] === "27" || object[:Tipo] === "35"}
          @nationalLongHigh << (nationalLongHighObj ? nationalLongHighObj[:Valor].to_f : nil)
          nationalLongVeryHighObj = tmcData[0..index_tmc].reverse.find{|object| object[:Tipo] === "1"|| object[:Tipo] === "3"|| object[:Tipo] === "6"|| object[:Tipo] === "9 "|| object[:Tipo] === "29" || object[:Tipo] === "34"}
          @nationalLongVeryHigh << (nationalLongVeryHighObj ? nationalLongVeryHighObj[:Valor].to_f : nil)
          nationalChangeShortObj = tmcData[0..index_tmc].reverse.find{|object| object[:Tipo] === "12" || object[:Tipo] === "21" || object[:Tipo] === "40"}
          @nationalChangeShort << (nationalChangeShortObj ? nationalChangeShortObj[:Valor].to_f : nil)
          nationalChangeLongLowObj = tmcData[0..index_tmc].reverse.find{|object| object[:Tipo] === "20" || object[:Tipo] === "23" || object[:Tipo] === "24" || object[:Tipo] === "40"}
          @nationalChangeLongLow << (nationalChangeLongLowObj ? nationalChangeLongLowObj[:Valor].to_f : nil)
          nationalChangeLongHighObj = tmcData[0..index_tmc].reverse.find{|object| object[:Tipo] === "30" || object[:Tipo] === "22" || object[:Tipo] === "23" || object[:Tipo] === "40"}
          @nationalChangeLongHigh << (nationalChangeLongHighObj ? nationalChangeLongHighObj[:Valor].to_f : nil)
          foreignLowTcmObj = tmcData[0..index_tmc].reverse.find{|object| object[:Tipo] === "15" || object[:Tipo] === "36" || object[:Tipo] === "38" || object[:Tipo] === "41"}
          @foreignLowTcm << (foreignLowTcmObj ? foreignLowTcmObj[:Valor].to_f : nil)
          foreignHighTcmObj = tmcData[0..index_tmc].reverse.find{|object| object[:Tipo] === "15" || object[:Tipo] === "36" || object[:Tipo] === "38" || object[:Tipo] === "42"}
          @foreignHighTcm << (foreignHighTcmObj ? foreignHighTcmObj[:Valor].to_f : nil)
          otherTcmObj = tmcData[0..index_tmc].reverse.find{|object| object[:Tipo] === 43}
          @otherTcm << (otherTcmObj ? otherTcmObj[:Valor].to_f : nil)
          day_str = day.strftime('%d/%m/%Y')
          @days << day_str
          @ufChart[day_str] = ufData[index_uf][:Valor].gsub('.','').gsub(',','.').to_f
          @dollarChart[day_str] = dollarData[index_dollar][:Valor].gsub(',','.').to_f
          @tmcChart[0][:data][day_str] = nationalShortLowObj ? nationalShortLowObj[:Valor].to_f : nil
          @tmcChart[1][:data][day_str] = nationalShortHighObj ? nationalShortHighObj[:Valor].to_f : nil
          @tmcChart[2][:data][day_str] = nationalLongVeryLowObj ? nationalLongVeryLowObj[:Valor].to_f : nil
          @tmcChart[3][:data][day_str] = nationalLongLowObj ? nationalLongLowObj[:Valor].to_f : nil
          @tmcChart[4][:data][day_str] = nationalLongHighObj ? nationalLongHighObj[:Valor].to_f : nil
          @tmcChart[5][:data][day_str] = nationalLongVeryHighObj ? nationalLongVeryHighObj[:Valor].to_f : nil
          @tmcChart[6][:data][day_str] = nationalChangeShortObj ? nationalChangeShortObj[:Valor].to_f : nil
          @tmcChart[7][:data][day_str] = nationalChangeLongLowObj ? nationalChangeLongLowObj[:Valor].to_f : nil
          @tmcChart[8][:data][day_str] = nationalChangeLongHighObj ? nationalChangeLongHighObj[:Valor].to_f : nil
          @tmcChart[9][:data][day_str] = foreignLowTcmObj ? foreignLowTcmObj[:Valor].to_f : nil
          @tmcChart[10][:data][day_str] = foreignHighTcmObj ? foreignHighTcmObj[:Valor].to_f : nil
          @tmcChart[11][:data][day_str] = otherTcmObj ? otherTcmObj[:Valor].to_f : nil
          day += 1.day
          @count += 1
        end
        @ufMin = @ufData.min
        @ufAvg = @ufData.sum / @count
        @ufMax = @ufData.max
        @dollarMin = @dollarData.min
        @dollarAvg = @dollarData.sum / @count
        @dollarMax = @dollarData.max
        @ufBw = @ufMax - @ufMin
        @dollarBw = @dollarMax - @dollarMin
      else
        @error = "Fecha de incio debe ser anterior a fecha de término"
      end
    end
  end
end
