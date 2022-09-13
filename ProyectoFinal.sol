// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//Javier Mulero Martin y Jorge del Valle Vazquez 

interface IExecutableProposal {
    function executeProposal(uint proposalId, uint numVotes, uint numTokens) external payable;
}
contract ProposalContract is IExecutableProposal {
    event Execute(uint _proposalId, uint _numVotes,uint _numTokens);
    function executeProposal(uint proposalId, uint numVotes,uint numTokens) override external payable {
        emit Execute(proposalId,numVotes,numTokens);
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract ERC20 is Context, IERC20, IERC20Metadata{
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function decimals() public view virtual override returns (uint8) {return 18;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {return _balances[account];}

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(address from,address to,uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}
contract ERC20TC is ERC20{
    uint256 private immutable _cap;
    address private _controller;
    constructor(string memory name_, string memory symbol_,uint256 cap_) ERC20(name_,symbol_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
        _controller = msg.sender;
    }
    function cap() public view virtual returns (uint256) {return _cap;}
    function controller() public view virtual returns (address) {return _controller;}
    function mint(uint256 amount) public virtual returns (bool) {
        require(msg.sender==_controller,"Only QuadraticVoting has permision to mint");
        require(ERC20.totalSupply() + amount <= _cap, "ERC20Capped: cap exceeded");
        _mint(msg.sender, amount);
        return true;
    }
    function burn(uint256 amount) public virtual returns (bool) {
        require(msg.sender==_controller,"Only QuadraticVoting has permision to burn");
        _burn(msg.sender, amount);
        return true;
    }
}

contract QuadraticVoting{
    // Struct de una propuesta
    struct Proposal{
        string title; // titulo
        string description; // descripcion
        uint256 budget; // presupuesto necesario para llevar a cabo la propuesta (0 en signalin)
        address contractProposal; // direccion de un contrato que implementa IExecutableProposal
        address creator; // creador
        bool approved; // true si aprobada
        bool canceled; // true si cancelada
        uint tokens; // numero de tokens en la propuesta
        uint votes; // numero de votos en la propuesta
    }

    address payable owner; // Propietario de la votacion
    ERC20TC tokenContract; // Contrato ERC20
    bool private votingOpen; // True si votacion abierta
    bool private lock; // Lock para seguridad
    uint private idNext; // Identificador actual de propuestas (va aumentando)
    uint private signalingCount; // Numero de propuestas signalin
    uint private pendingCount; // Numero de propuestas pendientes de aprobar (de financiacion)
    uint256 private tokenPrice; // Precio del token
    uint256 private totalBudget; // ETH de tokens comprados
    /* Obs: puede no coincidir con address(this).balance, pues los tokens de la propuestas signaling
     * o que se cancelan son devueltos a sus propietarios al finalizar la votacion, donde el propietario
     * recauda todo, pero el contrato tiene que mantenet el ETH de los tokens no gastados */

    mapping (address => bool) private isParticipant; // Participante -> true si es participante
    mapping (address => mapping (uint => uint)) private participantVotes;  // Participante -> Proposal - Votos a la propuesta
    address[] private participantIterator = new address[](0); // Para iterar participantVotes
    
    mapping (uint => Proposal) private proposals; // id propuesta -> datos propuesta
    uint[] private proposalsApproved = new uint[](0); // Indice de los proposals aprobados uint[]
    uint[] private proposalsIterator = new uint[](0); // Para iterar proposals y su length == numProposals del threshold

    /*
    En la creacion del contrato se debe proporcionar el precio en Wei de cada token y el
    numero maximo de tokens que se van a poner a la venta para votaciones. Entre otras
    cosas, el constructor debe crear el contrato de tipo ERC20 que gestiona los tokens.
    */

    constructor(uint256 _price, uint256 _supply) {
        owner = payable(msg.sender);
        tokenPrice = _price;
        tokenContract = new ERC20TC("Voting Token", "VT", _supply);
        tokenContract.mint(_supply);
        votingOpen = false;
        idNext = 1;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "Solo para el propietario del contrato.");
        _;
    }
    modifier isNewParticipant {
        require(isParticipant[msg.sender]==false, "El participante ya incorporado");
        _;
    }
    modifier enoughTokens {
        require(tokenContract.balanceOf(address(this))>0, " Faltan tokens");
        _;
    }
    modifier enoughPrice {
         require(msg.value >=tokenPrice, "Faltan ethers");
        _;
    }
    modifier onlyOpen {
        require(votingOpen, "Votacion no iniciada");
      _;
    }
    modifier onlyCreator(uint _id) {
        require(msg.sender==proposals[_id].creator, "No eres el creador");
      _;
    }
    modifier onlyParticipant {
        require(isParticipant[msg.sender], "El participante no esta incorporado");
      _;
    }
    modifier isProposal(uint _id) {
        require(proposals[_id].creator!=address(0), "La propuesta no existe");
        _;
    }
    modifier onlyPending(uint _id) {
        require(proposals[_id].creator!=address(0) && !proposals[_id].approved && !proposals[_id].canceled, "propuesta aprobada o cancelada");
        _;
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    /*
    Apertura del periodo de votacion. Solo lo puede ejecutar el usuario que
    ha creado el contrato. En la transaccion que ejecuta esta funcion se debe transferir el
    presupuesto inicial del que se va a disponer para financiar propuestas. Recuerda que
    este presupuesto total se modificara cuando se aprueben propuestas: se incrementara
    con las aportaciones en tokens de los votos de las propuestas que se vayan aprobando
    y se decrementara por el importe que se transfiere a las propuestas que se aprueben
    */

    function openVoting() public payable onlyOwner{
        require(!votingOpen, "Votacion ya iniciada");
        require(msg.value>0, "Necesita aportar un minimo de presupuesto");
        votingOpen = true;
        totalBudget = msg.value;
        // Reiniciamos el totalSupply al cap
        tokenContract.mint(tokenContract.cap() - tokenContract.totalSupply());
    }

    /* 
    Funcion que utilizan los participantes para inscribirse en la votacion. 
    Los participantes se pueden inscribir en cualquier momento, incluso antes de que se abra el periodo de votacion.
    Cuando se inscriben, los participantes deben transferir Ether para comprar tokens (al menos un token) que utilizaran para realizar sus votaciones.
    Esta funcion debe crear y asignar los tokens que se pueden comprar con ese importe.
    */

    function addParticipant() external payable isNewParticipant {
        // Deben tener dinero para comprar un token, o si ya eran participantes de una votacion 
        // de este mismo contrato, tienen que tener tokens 
        require(msg.value >= tokenPrice || tokenContract.balanceOf(msg.sender) > 0, "Todo participante necesita de tokens");
        // Cantidad de tokens compra
        uint256 tokenBought = msg.value / tokenPrice; // Aqui se queda la propina (msg.value % tokenPrice)
        
        // No puede superar la cantidad disponible de tokens
        require(tokenContract.balanceOf(address(this))>=tokenBought, " Faltan tokens");
    
        isParticipant[msg.sender] = true;
        // Transferir los tokens
        tokenContract.transfer(msg.sender, tokenBought);
        participantIterator.push(msg.sender); // !! ?? si ya tenia tokens, aqui no iba a estar, no?
        totalBudget+=msg.value % tokenPrice; // El exceso o cambio se dedica a apoyar las proposals 
    }

    /*
    Funcion que crea una propuesta. Cualquier participante puede crear propuestas, pero solo cuando la votacion esta abierta. 
    Recibe todos los atributos de la propuesta: titulo, descripcion, presupuesto necesario para llevar a cabo la propuesta
    (puede ser cero si es una propuesta de signaling) y la direccion de un contrato que implemente el interfaz ExecutableProposal, 
    que seria el receptor del dinero presupuestado en caso de ser aprobada la propuesta. 
    Debe devolver un identificador de la propuesta creada.
    */

    function addProposal(string memory _title, string memory _description, uint256 _amount, address _contractProposal) onlyParticipant onlyOpen external returns (uint256){
        uint propId = (idNext++);
        proposals[propId] = Proposal(_title,_description,_amount,_contractProposal,msg.sender,false,false,0,0);
        proposalsIterator.push(propId);
        if(_amount == 0)
            signalingCount++;
        else 
            pendingCount++;
        return propId;
    }
    
    /*
    Cancela una propuesta dado su identificador. Solo se puede ejecutar si la votacion esta abierta. El unico que puede realizar esta accion 
    es el creador de la propuesta. No se pueden cancelar propuestas ya aprobadas. Los tokens recibidos hasta el momento para votar la propuesta 
    deben ser devueltos a sus propietarios.
    */

    function cancelProposal(uint256 _propId) external onlyOpen onlyCreator(_propId) isProposal(_propId) onlyPending(_propId){
        uint l = participantIterator.length;
        address it;
        uint votes;
        // Devolver los tokens de los votantes de la propuesta (recorremos todos los participantes para ver quien ha votado)
        for(uint i = 0; i < l; ++i){
            it = participantIterator[i];
            votes = participantVotes[it][_propId];
            if(votes > 0){
                // El participante ha votado a la proposal => devolvemos tokens
                tokenContract.transfer(it, votes**2);
                participantVotes[it][_propId] = 0; // Ya no tiene ningun voto asociada
                delete participantVotes[it][_propId]; // Borramos el mapping para el participante it
            }
        }
               
        proposals[_propId].canceled = true; 
        proposals[_propId].tokens = 0;
        proposals[_propId].votes = 0;
        if(proposals[_propId].budget == 0) signalingCount--;
        else pendingCount--;
    }

    /*
    Esta funcion permite a un participante ya inscrito comprar mas tokens para depositar votos.
    */

    function buyTokens()  onlyParticipant enoughTokens enoughPrice external payable {
        uint256 tokenBought = msg.value / tokenPrice;
        require(tokenContract.balanceOf(address(this))>=tokenBought, "Se ha excedido el numero de tokens");
        tokenContract.transfer(msg.sender, tokenBought);
    }

    /*
    Operacion complementaria a la anterior: permite a un participante devolver tokens no gastados en votaciones y recuperar el dinero invertido en ellos.
    */

    function sellTokens() onlyParticipant external {
        uint tokenSell =  tokenContract.balanceOf(msg.sender); // Tokens a vender
        require(tokenSell > 0, "No dispone de Tokens");
        tokenContract.transferFrom(msg.sender, address(this), tokenSell); //***necesita allowance? el mismo que en stake
        uint256 price = tokenSell*tokenPrice;
        require(address(this).balance >= price, "SellTokens: El contrato QuadraticVoting no dispone de suficente balance para devoler");
        payable(msg.sender).transfer(price);
    }

    /*
    Devuelve la direccion del contrato ERC20 que utiliza el sistema de votacion para gestionar tokens. 
    De esta forma, los participantes pueden utilizarlo para operar con los tokens comprados (transferirlos, cederlos, etc.).
    */

    function getERC20Voting()  public view onlyParticipant returns (address) {
        return address(tokenContract);
    } 

    /*
    Devuelve un array con los identificadores de todas las propuestas pendientes de aprobar. Solo se puede ejecutar si la votacion esta abierta.
    */

    function getPendingProposals() public view onlyOpen returns (uint256[] memory) {
        uint256[] memory pending = new uint[](pendingCount);
        uint propId;
        uint l = proposalsIterator.length;
        uint j = 0;
        // Recorremos las propuestas y vemos cuales son pendientes
        for(uint256 i = 0; i < l ; i++){
            propId = proposalsIterator[i];
            // Las proposals pendientes son aquellas de financiacion que no han sido canceladas ni aprobadas
            if(proposals[propId].budget!=0 && !proposals[propId].canceled && !proposals[propId].approved) {
                pending[j] = propId;
                j++;
            }
        }
        return pending;
    }

    /*
    Devuelve un array con los identificadores de todas las propuestas aprobadas. Solo se puede ejecutar si la votacion esta abierta.
    */

    function getApprovedProposals() public view onlyOpen returns (uint256[] memory) {
        uint l = proposalsApproved.length;
        // Copia del array
        uint[] memory approved = new uint[](l);
        for(uint i = 0; i < l ; i++){
            approved[i] = proposalsApproved[i];
        }
        return approved;
    } 

    /*
    Devuelve un array con los identificadores de todas las propuestas de signaling (las que se han creado con presupuesto cero). 
    Solo se puede ejecutar si la votacion esta abierta.
    */

    function getSignalingProposals() public view onlyOpen returns (uint256[] memory){
        uint[] memory sigPro = new uint[](signalingCount);
        uint propId;
        uint l = proposalsIterator.length;
        uint j = 0;
        for(uint i = 0; i < l ; i++){
            propId = proposalsIterator[i];
            //***Si se ejecutan solo en close voting sobra el approve
            if (proposals[propId].budget == 0 && !proposals[propId].canceled && !proposals[propId].approved) {
                sigPro[j] = propId;
                j++;
            }
        }
        return sigPro;
    }

    /* 
    Devuelve los datos asociados a una propuesta dado su identificador. Solo se puede ejecutar si la votacion esta abierta.
    */

    function getProposalInfo(uint256 _propId) public view onlyOpen isProposal(_propId) returns (Proposal memory) {
        Proposal memory pro = proposals[_propId];
        return pro;
    }

    /* 
    Recibe un identificador de propuesta y la cantidad de votos que se quieren depositar y realiza el voto del participante que invoca esta funcion. 
    Calcula los tokens necesarios para depositar los votos que se van a depositar, comprueba que el participante posee los suficientes tokens 
    para comprar los votos y que ha cedido (con approve) el uso de esos tokens a la cuenta del contrato de la votacion. 
    Recuerda que un participante puede votar varias veces (y en distintas llamadas a stake) una misma propuesta con coste total cuadratico.

    El codigo de esta funcion debe transferir la cantidad de tokens correspondiente desde la cuenta del participante a la cuenta de este contrato 
    para poder operar con ellos. Como esta transferencia la realiza este contrato, el votante debe haber cedido previamente con approve los tokens 
    correspondientes a este contrato (esa cesion no se debe programar en QuadraticVoting: la debe realizar el participante con el contrato ERC20, que puede obtener con getERC20).
    */
    
    function stake(uint256 _propId, uint256 newVotes) public onlyOpen onlyParticipant isProposal(_propId) onlyPending(_propId){
        require(newVotes >= 1, "Necesario al menos un voto");
        uint prevVotes = participantVotes[msg.sender][_propId];// Los votos previos del participante a la propuesta
        // (nuevos+antiguos)**2-(antiguos)**2 = coste anadido por nuevos
        uint tokenCost = (newVotes+prevVotes)**2 - prevVotes**2;
        // El participante debe poseer los suficientes tokens para comprar los votos
        require(tokenContract.balanceOf(msg.sender)>= tokenCost, "Te faltan Tokens");
        // ha cedido (con approve) el uso de esos tokens a la cuenta del contrato de la votaciÂon
        // ***esta comprobacion es posible que se haga ya en ERC20
        require(tokenContract.allowance(msg.sender, address(this)) >= tokenCost, "Excede los tokens permitidos");
        tokenContract.transferFrom(msg.sender, address(this) , tokenCost);
        participantVotes[msg.sender][_propId] = participantVotes[msg.sender][_propId] + newVotes;
        proposals[_propId].tokens += tokenCost;
        proposals[_propId].votes += newVotes;
        //solo se debe recalcular el umbral de una propuesta cada vez que reciba votos.
        if(proposals[_propId].budget != 0 ){
            if(_checkAndExecuteProposal(_propId)){
                pendingCount--;
            }
        }
    }

    /*
    Dada una cantidad de votos y el identificador de la propuesta, retira (si es posible) esa cantidad de votos depositados por el participante 
    que invoca esta funcion de la propuesta recibida. Un participante solo puede retirar de una propuesta votos que el haya depositado anteriormente 
    y si la propuesta no ha sido aprobada todavia. Recuerda que debes devolver al participante los tokens que utilizo para depositar 
    los votos que ahora retira (por ejemplo, si habia depositado 4 votos a una propuesta y retira 2, se le deben devolver 12 tokens).
    */

    function withdrawFromProposal(uint256 _propId, uint256 retireVotes) public onlyOpen onlyParticipant isProposal(_propId) onlyPending(_propId){
        uint prevVotes = participantVotes[msg.sender][_propId];//los votos previos del participante a la propuesta
        require(prevVotes>0,"No hay votos");
        require((retireVotes >= 1) && (retireVotes <= prevVotes), "No hay tantos votos");
        uint256 tokenCost = prevVotes**2 - (prevVotes - retireVotes)**2;
        tokenContract.transfer(msg.sender, tokenCost);
        participantVotes[msg.sender][_propId] = participantVotes[msg.sender][_propId] - retireVotes;
        proposals[_propId].tokens -= tokenCost;
        proposals[_propId].votes -= retireVotes;
    }

    /*
    Funcion interna que comprueba si se cumplen las condiciones para ejecutar la propuesta y la ejecuta utilizando la funcion executeProposal del contrato 
    externo proporcionado al crear la propuesta. En esta llamada debe transferirse a dicho contrato el dinero presupuestado para su ejecucion. 
    Recuerda que debe actualizarse el presupuesto disponible para propuestas (y no olvides anadir al presupuesto el importe recibido de los tokens de votos 
    de la propuesta que se acaba de aprobar). Ademas deben eliminarse los tokens asociados a los votos recibidos por la propuesta, pues la ejecucion de la propuesta los consume.
    
    Cuando se realice la llamada a executeProposal del contrato externo, se debe limitar la cantidad maxima de gas que puede utilizar 
    para evitar que la propuesta pueda consumir todo el gas de la transaccion. Esta llamada debe consumir como maximo 100000 gas.
    */
    /*

    Una propuesta i es aprobada si se cumplen dos condiciones: 
    (1) el presupuesto del contrato de votacion mas el importe recaudado por los votos recibidos es suficiente para financiar la propuesta 
    (2) el numero de votos recibidos supera un umbral
    */
    // Solo se emplea para propuestas de financiación
    function _checkAndExecuteProposal(uint _propId) isProposal(_propId) onlyPending(_propId) internal returns (bool){
        require(!lock, "Bloqueado, ya hay una ejecucion en curso");
        //para trabajar con enteros cambiamos la formula multiplicando todo por 10
        // Multiplicamos todo por 10*totalBudget y asi trabajar con enteros
        uint threshold = (2*totalBudget + 10*proposals[_propId].budget) * (participantIterator.length) + ((pendingCount+signalingCount)*10*totalBudget);
        //*** Se deberia actualiza el totalBudget con los prices de los tokens cuando se van anadiendo votos?
        //proposals[propId].amount != 0 && 
        if(totalBudget + proposals[_propId].tokens*tokenPrice >= proposals[_propId].budget && proposals[_propId].votes*10*totalBudget >= threshold){
            lock = true;

            IExecutableProposal(payable(proposals[_propId].contractProposal)).executeProposal{value : proposals[_propId].budget, gas :100000}(_propId, proposals[_propId].votes,proposals[_propId].tokens);
            // Al aprobarse se queda el valor de los tokens en el contrato
            // el importe recaudado por los votos
            totalBudget += proposals[_propId].tokens*tokenPrice;
            // El presupuesto necesario para la proposal se resta del disponible
            totalBudget -= proposals[_propId].budget; // ?? Para que se usa
            proposals[_propId].approved = true;
            proposalsApproved.push(_propId);
            //***burn
            // solo puede hacer burn QuadraticVoting
            tokenContract.burn(proposals[_propId].tokens);
            
            lock = false;
            return true;
        }
        return false;
    }

    /*
    Cierre del periodo de votacion. Solo puede ejecutar esta funcion el usuario que ha creado el contrato de votacion. Cuando termina el periodo de votacion se deben
    realizar entre otras las siguientes tareas:
        - Las propuestas que no han podido ser aprobadas son descartadas y los tokens recibidos por esas propuestas es devuelto a sus propietarios.
        - las propuestas de signaling son ejecutadas y los tokens recibidos mediante votos es devuelto a sus propietarios.
        - El presupuesto de la votacion no gastado en las propuestas se transfiere al propietario del contrato de votación.
    Cuando se cierra el proceso de votacion no se deben aceptar nuevas propuestas ni votos y el contrato QuadraticVoting debe quedarse en un estado que permita abrir un nuevo proceso de votacion.
    Esta funcion puede consumir una gran cantidad de gas, tenlo en cuenta al programarla y durante las pruebas.
    */

    function closeVoting() public onlyOpen onlyOwner{
        votingOpen = false;
        uint propId;
        address partId;
        //Las propuestas que no han podido ser aprobadas son descartadas y los tokens recibidos por esas propuestas es devuelto a sus propietarios
        uint l=proposalsIterator.length;
        uint le=participantIterator.length;
        for(uint i = 0; i < l; i++){
            propId = proposalsIterator[i];
            if(!proposals[propId].canceled && !proposals[propId].approved){
                for(uint j=0; j < le; j++){
                    partId = participantIterator[j];
                    uint votes = participantVotes[partId][propId];
                    if(votes >0) {
                        tokenContract.transfer(partId,votes**2);
                    }
                    //Las propuestas de signaling son ejecutadas y los tokens recibidos mediante votoses devuelto a sus propietarios(ya hecho por el if anterior)
                    if(proposals[propId].budget == 0) {
                        IExecutableProposal(payable(proposals[propId].contractProposal)).executeProposal{gas :100000}(propId, proposals[propId].votes,proposals[propId].tokens);
                    }
                }
            }
        }
        // El presupuesto de la votacion no gastado en las propuestas se transfiere al propietario del contrato de votacion.
        // EL balance del contrao es la suma / calculos de la cantidad aportada inicialmente mas los tokens en posesion de participantes
        owner.transfer(totalBudget);
        totalBudget = 0;
        // Borrado de estructuras (para dejar preparado QuadraticVoting para una nueva votación)
        for(uint i = 0; i < le; i++){
            partId = participantIterator[i];
            for(uint j = 0; j < l; j++){
                propId = proposalsIterator[j];
                delete participantVotes[partId][propId];
            }
        }
        for(uint j=0; j < l; j++){
                propId = proposalsIterator[j];
                delete proposals[propId];
        }
        participantIterator = new address[](0);
        proposalsApproved = new uint[](0);
        proposalsIterator = new uint[](0);
        idNext = 1;
        signalingCount = 0;
        pendingCount = 0;
    }
}
