// DEFAULT SETTINGS
string status = "Available";
integer preco = 500;
integer dias = 5;

// MENU AND CONFIRMATION CHANNELS
integer canalMenu = -999;
integer canalFluxoCadastro = -555;
integer canalConfirmacaoBloqueio = -777;

// CLIENT / OCCUPANT DATA AND PENDING STATUS
key locatarioID = NULL_KEY;
string locatarioNome = "None";
integer dataVencimento = 0;

// TENANT AND VALUE HISTORY
string historicoInquilinos = "No previous records.";
integer totalArrecadadoGeral = 0;

// Temporary variables for registration flow
string tempOcupante = "";
integer tempValor = 0;
integer tempTempo = 0;
integer etapaCadastro = 0; 

// Pending status control variables
string nomeTemporario = "";
key clientePagouID = NULL_KEY;
integer valorPagoPendente = 0;
integer aguardandoConfirmacao = FALSE;
integer prontoParaConfirmar = FALSE; 

// HELPER FUNCTION: Formats Unix Timestamp to "DD/MM/YYYY HH:MM"
string formatarDataHora(integer timestamp)
{
    integer tempoLocal = timestamp - 10800; // GMT-3 (Brazil)
    if (tempoLocal < 0) tempoLocal = 0;

    integer ano = 1970;
    integer segundosPorDia = 86400;
    integer diasTotais = tempoLocal / segundosPorDia;
    integer segundosRestantes = tempoLocal % segundosPorDia;

    integer hora = segundosRestantes / 3600;
    integer minuto = (segundosRestantes % 3600) / 60;

    integer d = diasTotais;
    
    while(TRUE)
    {
        integer diasNoAno = 365;
        if ((ano % 4 == 0 && ano % 100 != 0) || (ano % 400 == 0)) diasNoAno = 366;
        if (d >= diasNoAno)
        {
            d -= diasNoAno;
            ano++;
        }
        else jump saiAnos;
    }
    @saiAnos;

    list mesesDias = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if ((ano % 4 == 0 && ano % 100 != 0) || (ano % 400 == 0)) mesesDias = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    integer mes = 1;
    integer m = 0;
    while(m < 12)
    {
        integer diasMes = llList2Integer(mesesDias, m);
        if (d >= diasMes)
        {
            d -= diasMes;
            mes++;
        }
        else jump saiMeses;
        m++;
    }
    @saiMeses;

    integer dia = d + 1;

    string sDia = (string)dia; if (dia < 10) sDia = "0" + sDia;
    string sMes = (string)mes; if (mes < 10) sMes = "0" + sMes;
    string sHora = (string)hora; if (hora < 10) sHora = "0" + sHora;
    string sMinuto = (string)minuto; if (minuto < 10) sMinuto = "0" + sMinuto;

    return sDia + "/" + sMes + "/" + (string)ano + " " + sHora + ":" + sMinuto;
}

// FUNCTION: Updates Floating Text
atualizarTexto()
{
    if (status == "Available")
    {
        if (aguardandoConfirmacao)
        {
            llSetText("🟡 AWAITING CONFIRMATION\nPayment from: " + llKey2Name(clientePagouID) + " (L$ " + (string)valorPagoPendente + ")\n[ Owner must confirm in Menu ]", <1.0, 0.5, 0.0>, 1.0);
        }
        else if (prontoParaConfirmar)
        {
            llSetText("✅ REGISTRATION READY\nOccupant: " + tempOcupante + " | L$ " + (string)tempValor + " (" + (string)tempTempo + " days)\n[ Click 'Confirm' in the menu ]", <1.0, 0.5, 0.0>, 1.0);
        }
        else
        {
            llSetText("🟢 PROPERTY AVAILABLE\nPrice: L$ " + (string)preco + " (" + (string)dias + " days)", <0.0, 1.0, 0.0>, 1.0);
            llSetPayPrice(PAY_HIDE, [preco, PAY_HIDE, PAY_HIDE, PAY_HIDE]);
        }
    }
    else if (status == "Occupied")
    {
        integer tempoRestante = dataVencimento - llGetUnixTime();
        if (tempoRestante < 0) tempoRestante = 0;
        
        integer d = tempoRestante / 86400;
        integer h = (tempoRestante % 86400) / 3600;
        
        string dataVencFormatada = formatarDataHora(dataVencimento);

        llSetText(
        "🔴 PROPERTY OCCUPIED\n"
        + "Occupant: " + locatarioNome + "\n"
        + "Rent: L$ " + (string)preco + "\n"
        + "Expires: " + dataVencFormatada + "\n"
        + "Time Remaining: " + (string)d + " days and " + (string)h + " hours",
        <1.0, 0.0, 0.0>,
        1.0
        );
    }
    else if (status == "Blocked")
    {
        llSetText("🚫 PROPERTY BLOCKED\n[ Restricted access ]", <1.0, 0.0, 0.0>, 1.0);
    }
}

// FUNCTION: Saves data to internal memory
salvarDadosInquilino()
{
    llLinksetDataWrite("status", status);
    llLinksetDataWrite("locatarioNome", locatarioNome);
    llLinksetDataWrite("locatarioID", (string)locatarioID);
    llLinksetDataWrite("dataVencimento", (string)dataVencimento);
    llLinksetDataWrite("dias", (string)dias);
    llLinksetDataWrite("preco", (string)preco);
    llLinksetDataWrite("aguardandoConfirmacao", (string)aguardandoConfirmacao);
    llLinksetDataWrite("clientePagouID", (string)clientePagouID);
    llLinksetDataWrite("valorPagoPendente", (string)valorPagoPendente);
    llLinksetDataWrite("historico", historicoInquilinos);
    llLinksetDataWrite("totalArrecadadoGeral", (string)totalArrecadadoGeral);
}

// FUNCTION: Loads saved data
carregarDadosInquilino()
{
    if (llLinksetDataRead("status") != "")
    {
        status = llLinksetDataRead("status");
        locatarioNome = llLinksetDataRead("locatarioNome");
        locatarioID = (key)llLinksetDataRead("locatarioID");
        dataVencimento = (integer)llLinksetDataRead("dataVencimento");
        
        if (llLinksetDataRead("dias") != "") dias = (integer)llLinksetDataRead("dias");
        if (llLinksetDataRead("preco") != "") preco = (integer)llLinksetDataRead("preco");
            
        aguardandoConfirmacao = (integer)llLinksetDataRead("aguardandoConfirmacao");
        clientePagouID = (key)llLinksetDataRead("clientePagouID");
        if (llLinksetDataRead("valorPagoPendente") != "") valorPagoPendente = (integer)llLinksetDataRead("valorPagoPendente");
        
        string h = llLinksetDataRead("historico");
        if (h != "") historicoInquilinos = h;

        if (llLinksetDataRead("totalArrecadadoGeral") != "") totalArrecadadoGeral = (integer)llLinksetDataRead("totalArrecadadoGeral");
    }
}

// FUNCTION: Adds to history
adicionarAoHistorico(string nomeAntigo, integer valorPago)
{
    if (nomeAntigo != "None" && nomeAntigo != "")
    {
        totalArrecadadoGeral += valorPago;

        string registro = nomeAntigo;
        integer tamanhoNome = llStringLength(nomeAntigo);
        
        while (tamanhoNome < 15)
        {
            registro += " ";
            tamanhoNome++;
        }
        registro += "L$ " + (string)valorPago;

        if (historicoInquilinos == "No previous records.")
        {
            historicoInquilinos = "OCCUPANT       PRICE\n" + registro;
        }
        else
        {
            historicoInquilinos = historicoInquilinos + "\n" + registro;
        }
    }
}

default
{
    state_entry()
    {
        llSetObjectName("Rental Manager v1.00 EN");
        
        // --- TOTAL RESET FOR SALES/PACKAGED VERSION ---
        // Clears history, totals, and resets the LinksetData memory inside the object instantly
        historicoInquilinos = "No previous records.";
        totalArrecadadoGeral = 0;
        status = "Available";
        locatarioID = NULL_KEY;
        locatarioNome = "None";
        dataVencimento = 0;
        aguardandoConfirmacao = FALSE;
        prontoParaConfirmar = FALSE;
        clientePagouID = NULL_KEY;
        valorPagoPendente = 0;
        
        // Overwrites LinksetData memory with fresh factory defaults
        salvarDadosInquilino();
        // ---------------------------------------------
        
        if (status == "Occupied") llSetTimerEvent(60.0);
        
        llListen(canalMenu, "", llGetOwner(), "");
        llListen(canalFluxoCadastro, "", llGetOwner(), "");
        llListen(canalConfirmacaoBloqueio, "", llGetOwner(), "");
        
        atualizarTexto();
    }

    touch_start(integer total_number)
    {
        key avatarID = llDetectedKey(0);

        if (avatarID == llGetOwner())
        {
            list botoes = ["History", "Close", "Restrict", "Register", "Confirm", "Release"];
            
            string mensagemPainel = "Property Control Panel\n\n" +
                                    "👤 " + locatarioNome + "\n" +
                                    "💰 L$ " + (string)preco + "\n" +
                                    "⏱️ " + (string)dias + " days\n" +
                                    "📅 Expires: " + formatarDataHora(dataVencimento) + "\n" +
                                    "📊 Total Collected: L$ " + (string)totalArrecadadoGeral + "\n" +
                                    "📌 Status: " + status;
            
            if (aguardandoConfirmacao)
            {
                mensagemPainel = "🚨 PENDING PAYMENT FROM: " + llKey2Name(clientePagouID) + " (L$ " + (string)valorPagoPendente + ")\nClick 'Confirm' to accept.";
            }
            else if (prontoParaConfirmar)
            {
                mensagemPainel = "📝 REGISTRATION READY TO APPLY!\n- Occupant: " + tempOcupante + "\n- Price: L$ " + (string)tempValor + "\n- Time: " + (string)tempTempo + " days\nClick 'Confirm' to change to Occupied.";
            }

            llDialog(avatarID, mensagemPainel, botoes, canalMenu);
        }
        else
        {
            if (status == "Available")
            {
                if (aguardandoConfirmacao || prontoParaConfirmar)
                    llRegionSayTo(avatarID, 0, "This property is awaiting finalization by the owner.");
                else
                    llRegionSayTo(avatarID, 0, "To rent, right-click the property and choose 'Pay' (L$ " + (string)preco + ").");
            }
            else
            {
                llRegionSayTo(avatarID, 0, "This property is already rented.");
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == canalMenu)
        {
            if (message == "Register" && (status == "Occupied" || prontoParaConfirmar))
            {
                if (status == "Occupied")
                    llOwnerSay("⚠️ Action denied: The property is occupied. Release it first.");
                else
                    llOwnerSay("⚠️ Action denied: There is already a saved registration awaiting confirmation.");
                return;
            }

            if (message == "Confirm" && status == "Occupied")
            {
                llOwnerSay("⚠️ Action denied: The property is already occupied.");
                return;
            }

            if (message == "Register")
            {
                etapaCadastro = 1;
                tempValor = preco; 
                tempTempo = dias;  
                llTextBox(id, "Step 1/3: Type the OCCUPANT's name:", canalFluxoCadastro);
            }
            else if (message == "Confirm")
            {
                if (prontoParaConfirmar)
                {
                    if (locatarioNome != "None" && locatarioNome != "") 
                        adicionarAoHistorico(locatarioNome, preco);

                    locatarioNome = tempOcupante;
                    preco = tempValor;
                    dias = tempTempo;
                    locatarioID = NULL_KEY;

                    status = "Occupied";
                    dataVencimento = llGetUnixTime() + (dias * 86400);
                    
                    prontoParaConfirmar = FALSE;
                    tempOcupante = "";

                    salvarDadosInquilino();
                    llSetTimerEvent(60.0);
                    atualizarTexto();

                    llOwnerSay("✅ Status changed to OCCUPIED! Occupant: " + locatarioNome + " (L$ " + (string)preco + ")");
                }
                else if (aguardandoConfirmacao || nomeTemporario != "")
                {
                    if (locatarioNome != "None" && locatarioNome != "") 
                        adicionarAoHistorico(locatarioNome, preco);

                    if (nomeTemporario != "") locatarioNome = nomeTemporario;
                    else if (clientePagouID != NULL_KEY) locatarioNome = llKey2Name(clientePagouID);

                    if (clientePagouID != NULL_KEY) locatarioID = clientePagouID;

                    if (valorPagoPendente > 0) preco = valorPagoPendente;

                    status = "Occupied";
                    dataVencimento = llGetUnixTime() + (dias * 86400);
                    aguardandoConfirmacao = FALSE;
                    nomeTemporario = "";

                    salvarDadosInquilino();
                    llSetTimerEvent(60.0);
                    atualizarTexto();

                    llOwnerSay("✅ Rent finalized for: " + locatarioNome + " (L$ " + (string)preco + ")");
                    if (locatarioID != NULL_KEY) llRegionSayTo(locatarioID, 0, "Your rental has been confirmed by the owner!");
                }
                else
                {
                    llOwnerSay("⚠️ No pending issues or registrations awaiting confirmation.");
                }
            }
            else if (message == "Release")
            {
                if (locatarioNome != "None" && status != "Blocked") 
                    adicionarAoHistorico(locatarioNome, preco);

                status = "Available";
                locatarioID = NULL_KEY;
                locatarioNome = "None";
                dataVencimento = 0;
                nomeTemporario = "";
                aguardandoConfirmacao = FALSE;
                prontoParaConfirmar = FALSE;
                clientePagouID = NULL_KEY;
                valorPagoPendente = 0;
                llSetTimerEvent(0.0);
                salvarDadosInquilino();
                atualizarTexto();
                llOwnerSay("Property released and saved in history. Status: Available.");
            }
            else if (message == "History")
            {
                llOwnerSay("📜 OCCUPANT HISTORY:\n\n" + historicoInquilinos + "\n----------------------------------\nTOTAL         L$ " + (string)totalArrecadadoGeral);
            }
            else if (message == "Restrict")
            {
                llDialog(id, "⚠️ ARE YOU SURE YOU WANT TO RESTRICT/BLOCK THE PROPERTY?\nThis will end the current rental (if any).", ["Yes", "No"], canalConfirmacaoBloqueio);
            }
            else if (message == "Close")
            {
                aguardandoConfirmacao = FALSE;
                prontoParaConfirmar = FALSE;
                clientePagouID = NULL_KEY;
                valorPagoPendente = 0;
                nomeTemporario = "";
                tempOcupante = "";
                atualizarTexto();
                llOwnerSay("❌ Pending operation discarded.");
            }
        }
        else if (channel == canalConfirmacaoBloqueio)
        {
            if (message == "Yes")
            {
                if (locatarioNome != "None" && status == "Occupied") 
                    adicionarAoHistorico(locatarioNome, preco);

                status = "Blocked";
                locatarioID = NULL_KEY;
                locatarioNome = "Blocked";
                dataVencimento = 0;
                salvarDadosInquilino();
                llSetTimerEvent(0.0);
                atualizarTexto();
                llOwnerSay("🔒 Property successfully restricted/blocked.");
            }
            else
            {
                llOwnerSay("❌ Restriction operation canceled.");
            }
        }
        else if (channel == canalFluxoCadastro)
        {
            if (etapaCadastro == 1)
            {
                string nomeInformado = llStringTrim(message, STRING_TRIM);
                
                if (nomeInformado == "")
                {
                    llTextBox(id, "⚠️ Invalid name!\nType the OCCUPANT's name:", canalFluxoCadastro);
                    return;
                }

                tempOcupante = llToUpper(nomeInformado);
                etapaCadastro = 2;
                
                llDialog(id, "Step 2/3: Choose the PRICE in L$\n(Current Price: L$ " + (string)tempValor + ")", [(string)tempValor, "Other...", "Cancel"], canalFluxoCadastro);
            }
            else if (etapaCadastro == 2)
            {
                if (message == "Other...")
                {
                    llTextBox(id, "Type the new PRICE in L$:", canalFluxoCadastro);
                }
                else if (message == "Cancel")
                {
                    etapaCadastro = 0;
                    llOwnerSay("❌ Registration canceled.");
                }
                else
                {
                    integer valorInformado = (integer)message;
                    if (valorInformado > 0) tempValor = valorInformado;

                    etapaCadastro = 3;
                    llDialog(id, "Step 3/3: Choose the TIME in days\n(Current Time: " + (string)tempTempo + " days)", [(string)tempTempo, "Other...", "Cancel"], canalFluxoCadastro);
                }
            }
            else if (etapaCadastro == 3)
            {
                if (message == "Other...")
                {
                    llTextBox(id, "Type the new TIME in days (1 to 365):", canalFluxoCadastro);
                }
                else if (message == "Cancel")
                {
                    etapaCadastro = 0;
                    llOwnerSay("❌ Registration canceled.");
                }
                else
                {
                    integer diasInformados = (integer)message;
                    
                    if (diasInformados >= 1 && diasInformados <= 365) 
                    {
                        tempTempo = diasInformados;
                        etapaCadastro = 0;
                        prontoParaConfirmar = TRUE; 

                        atualizarTexto();
                        llOwnerSay("📝 Data configured!\n- Occupant: " + tempOcupante + "\n- Price: L$ " + (string)tempValor + "\n- Time: " + (string)tempTempo + " days\n👉 Click 'Confirm' in the main menu to apply.");
                    }
                    else
                    {
                        llTextBox(id, "⚠️ INVALID VALUE!\nPlease enter a time between 1 and 365 days:", canalFluxoCadastro);
                    }
                }
            }
        }
    }

    money(key id, integer amount)
    {
        if (status == "Available" && amount == preco)
        {
            clientePagouID = id;
            valorPagoPendente = amount;
            aguardandoConfirmacao = TRUE; 
            
            atualizarTexto();
            llRegionSayTo(id, 0, "Payment received! Awaiting owner confirmation.");
            llOwnerSay("💰 PAYMENT FROM " + llKey2Name(id) + " (L$ " + (string)amount + "). Go to the menu and click 'Confirm'.");
        }
        else if (status == "Occupied" && id == locatarioID && amount == preco)
        {
            dataVencimento = dataVencimento + (dias * 86400);
            totalArrecadadoGeral += amount; 
            salvarDadosInquilino();
            atualizarTexto();
            
            llRegionSayTo(id, 0, "Renewal accepted! Extra " + (string)dias + " days added.");
            llOwnerSay("🔄 Rent renewed by " + locatarioNome + " (+ L$ " + (string)amount + ")");
        }
        else
        {
            llRegionSayTo(id, 0, "Incorrect amount or property occupied. Refunding payment.");
            llGiveMoney(id, amount);
        }
    }

    timer()
    {
        integer agora = llGetUnixTime();
        atualizarTexto();

        if (agora >= dataVencimento && status == "Occupied")
        {
            llOwnerSay("🚨 The rent of " + locatarioNome + " has expired!");
            llRegionSayTo(locatarioID, 0, "Your rental period has ended.");
            
            adicionarAoHistorico(locatarioNome, preco);
            
            status = "Available";
            locatarioID = NULL_KEY;
            locatarioNome = "None";
            dataVencimento = 0;
            nomeTemporario = "";
            aguardandoConfirmacao = FALSE;
            prontoParaConfirmar = FALSE;
            clientePagouID = NULL_KEY;
            valorPagoPendente = 0;
            
            salvarDadosInquilino();
            llSetTimerEvent(0.0);
            atualizarTexto();
        }
    }
}