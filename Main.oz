functor
import
  ProjectLib
  Browser
  OS
  System
  Application
define
  CWD = {Atom.toString {OS.getCWD}}#"/"
  Browse = proc {$ Buf} {Browser.browse Buf} end
  Print = proc{$ S} {System.print S} end
  Args = {Application.getArgs record('nogui'(single type:bool default:false optional:true)
          'db'(single type:string default:CWD#"database.txt"))} 
in 
  local
    NoGUI = Args.'nogui'
    DB = Args.'db'
    ListOfCharacters = {ProjectLib.loadDatabase file Args.'db'}
    NewCharacter = {ProjectLib.loadCharacter file CWD#"new_character.txt"}
    % Vous devez modifier le code pour que cette variable soit
    % assigné un argument 	
    ListOfAnswersFile = CWD#"test_answers.txt"
    ListOfAnswers = {ProjectLib.loadCharacter file CWD#"test_answers.txt"}

    % get next best question to ask to split possible anwers
    fun {NextQuestion Data}
      if {Width Data.1} == 1 orelse {Length Data} == 1 then nil
      else {Nth {Arity Data.1} 2} % TODO return best question
      end
    end

    fun {TreeBuilder Data}
      % get tuple with a list of true and a list of false (with the question removed)
      fun {Split Data Question}
        T F Ask RemoveQ
      in
        Ask = fun {$ E} E.Question end
        {List.partition Data Ask T F} % split true (in T) and false (in F) results to Ask
        RemoveQ = fun {$ E} {Record.subtract E Question} end % remove question from db records
        question(Question
                true:{TreeBuilder {Map T RemoveQ}}
                false:{TreeBuilder {Map F RemoveQ}})
      end
    in
      if Data == nil then nil
      else
        NextQ = {NextQuestion Data}
      in
        if NextQ == nil then
          {Map Data fun {$ E} E.1 end}
        else
          {Split Data NextQ}
        end
      end
    end

    fun {GameDriver Tree}
      Result
      fun {Next Tree}
        case Tree
          of nil then {ProjectLib.surrender}
          [] question(Q true:T false:F) then
            if {ProjectLib.askQuestion Q} then {Next T}
            else {Next F} end
          [] L then {ProjectLib.found L} % TODO if multiple, ask for every match
        end
      end
    in
      Result = {Next Tree}

      if Result == false then
        % Arf ! L'algorithme s'est trompé !
        {Print 'Je me suis trompé\n'}
        {Print {ProjectLib.surrender}}

        % warning, Browse do not work in noGUI mode
        {Browse {ProjectLib.askQuestion 'A-t-il des cheveux roux ?'}}
      else
        {Print Result}
      end
      
      unit % toujours renvoyer unit
    end
  in
    {ProjectLib.play opts(characters:ListOfCharacters driver:GameDriver 
                          noGUI:NoGUI builder:TreeBuilder 
                          autoPlay:ListOfAnswers newCharacter:NewCharacter)}
    {Application.exit 0}
  end
end
