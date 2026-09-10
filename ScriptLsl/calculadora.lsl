// Calculadora Científica por Menu Multifases (Versão Final Estável)
integer CANAL_MENU = -888877;
integer listener_handle;

string estado_atual = "";
float acumulado = 0.0;
string operacao = "";

// Menu 1: Números de 0 a 6
abrir_menu_num1(key user)
v{
    llListenRemove(listener_handle);
    listener_handle = llListen(CANAL_MENU, "", user, "");
    
    string visor = "0";
    if (estado_atual != "") {
        visor = estado_atual;
    }
    
    if (acumulado != 0.0) {
        visor = visor + " (Ant: " + (string)acumulado + ")";
    }
    
    llDialog(user, "\n[Visor: " + visor + "]\nEscolha:", 
             ["0", "1", "2", "3", "4", "5", "6", "Mais", "C", "Sair"], CANAL_MENU);
}

// Menu 2: Números finais (7 a 9) e Operações Básicas
abrir_menu_num2(key user)
{
    llListenRemove(listener_handle);
    listener_handle = llListen(CANAL_MENU, "", user, "");
    
    string visor = "0";
    if (estado_atual != "") {
        visor = estado_atual;
    }
    
    llDialog(user, "\n[Visor: " + visor + "]\nOperações:", 
             ["7", "8", "9", ".", "+", "-", "*", "/", "=", "Voltar", "Científica", "Sair"], CANAL_MENU);
}

// Menu 3: Funções Científicas Avançadas
abrir_menu_cientifico(key user)
{
    llListenRemove(listener_handle);
    listener_handle = llListen(CANAL_MENU, "", user, "");
    
    llDialog(user, "\n--- Funções Científicas ---", 
             ["sqrt", "sin", "cos", "tan", "log", "ln", "pi", "e", "Voltar", "Sair"], CANAL_MENU);
}

default
{
    state_entry()
    {
        llOwnerSay("Calculadora pronta! Clique no objeto para abrir.");
    }

    touch_start(integer total_number)
    {
        key user = llDetectedKey(0);
        if (user == llGetOwner()) {
            abrir_menu_num1(user);
        } else {
            llInstantMessage(user, "Apenas o dono pode usar esta calculadora.");
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel != CANAL_MENU) return;
        
        if (message == "Sair") {
            llListenRemove(listener_handle);
            return;
        }
        
        if (message == "Voltar") {
            abrir_menu_num1(id);
            return;
        }
        
        if (message == "Mais") {
            abrir_menu_num2(id);
            return;
        }
        
        if (message == "Científica") {
            abrir_menu_cientifico(id);
            return;
        }
        
        // Digitar números ou ponto decimal
        if (message == "0" || message == "1" || message == "2" || message == "3" || 
            message == "4" || message == "5" || message == "6" || message == "7" || 
            message == "8" || message == "9" || message == ".") 
        {
            estado_atual = estado_atual + message;
            
            if (message == "7" || message == "8" || message == "9" || message == ".") {
                abrir_menu_num2(id);
            } else {
                abrir_menu_num1(id);
            }
        }
        // Operadores Básicos (+, -, *, /)
        else if (message == "+" || message == "-" || message == "*" || message == "/") 
        {
            if (estado_atual != "") {
                acumulado = (float)estado_atual;
                operacao = message;
                estado_atual = "";
            }
            abrir_menu_num2(id);
        }
        // Botão de Igual (=)
        else if (message == "=") 
        {
            if (operacao != "" && estado_atual != "") {
                float val2 = (float)estado_atual;
                
                if (operacao == "+") {
                    acumulado = acumulado + val2;
                }
                else if (operacao == "-") {
                    acumulado = acumulado - val2;
                }
                else if (operacao == "*") {
                    acumulado = acumulado * val2;
                }
                else if (operacao == "/") {
                    if (val2 != 0.0) {
                        acumulado = acumulado / val2;
                    } else {
                        llOwnerSay("ERRO: Divisão por zero.");
                    }
                }
                
                estado_atual = (string)acumulado;
                operacao = "";
            }
            abrir_menu_num2(id);
        }
        // Botão Limpar (C)
        else if (message == "C") 
        {
            estado_atual = "";
            acumulado = 0.0;
            operacao = "";
            abrir_menu_num1(id);
        }
        // Funções Científicas
        else 
        {
            float val = acumulado;
            if (estado_atual != "") {
                val = (float)estado_atual;
            }

            float res = 0.0;
            integer erro = 0;

            if (message == "sqrt") {
                if (val >= 0.0) {
                    res = llSqrt(val);
                } else {
                    llOwnerSay("ERRO: Raiz quadrada de número negativo.");
                    erro = 1;
                }
            }
            else if (message == "sin") {
                res = llSin(val * DEG_TO_RAD);
            }
            else if (message == "cos") {
                res = llCos(val * DEG_TO_RAD);
            }
            else if (message == "tan") {
                res = llTan(val * DEG_TO_RAD);
            }
            else if (message == "log") {
                if (val > 0.0) {
                    res = llLog10(val);
                } else {
                    llOwnerSay("ERRO: Log de zero ou negativo.");
                    erro = 1;
                }
            }
            else if (message == "ln") {
                if (val > 0.0) {
                    res = llLog(val);
                } else {
                    llOwnerSay("ERRO: Ln de zero ou negativo.");
                    erro = 1;
                }
            }
            else if (message == "pi") {
                res = PI;
            }
            else if (message == "e") {
                res = 2.718281828;
            }

            if (erro == 0) {
                acumulado = res;
                estado_atual = (string)res;
            }
            abrir_menu_cientifico(id);
        }
    }
}