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

    fun {TreeBuilder Database}
      leaf(nil)
    end

    fun {GameDriver Tree}
      Result
    in
      if {ProjectLib.askQuestion 'Est-ce que c\'est une fille ?'} then
        if {ProjectLib.askQuestion 'Porte-t-il des lunettes ?'} then
          Result = {ProjectLib.found ['Minerva McGonagall']}
        else
          if {ProjectLib.askQuestion 'A-t-il des cheveux roux ?'} then
            Result = {ProjectLib.found ['Ginny Weasley']}
          else
            Result = {ProjectLib.found ['Hermione Granger']}
          end
        end
      else
        if {ProjectLib.askQuestion 'A-t-il des cheveux noirs ?'} then
          if {ProjectLib.askQuestion 'Porte-t-il des lunettes ?'} then
            Result = {ProjectLib.found ['Harry Potter']}
          else
            Result = {ProjectLib.found ['Severus Rogue']}
          end
        else
          Result = {ProjectLib.found ['Ron Weasley']}
        end
      end

      if Result == false then
        % Arf ! L'algorithme s'est trompé !
        {Print 'Je me suis trompé\n'}
        {Print {ProjectLib.surrender}}

        % warning, Browse do not work in noGUI mode
        {Browse {ProjectLib.askQuestion 'A-t-il des cheveux roux ?'}}
      else
        {Print Result}
      end

      % Toujours renvoyer unit
      unit
    end
  in
    {ProjectLib.play opts(characters:ListOfCharacters driver:GameDriver 
                          noGUI:NoGUI builder:TreeBuilder 
                          autoPlay:ListOfAnswers newCharacter:NewCharacter)}
    {Application.exit 0}
  end
end
