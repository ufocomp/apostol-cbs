/*++

Program name:

  Apostol Web Service

Module Name:

  NHBot.cpp

Notices:

  Process: NiceHash Bot

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#include "Core.hpp"
#include "NiceHash.hpp"
//----------------------------------------------------------------------------------------------------------------------

#define SYSTEM_PROVIDER_NAME "system"
#define SERVICE_APPLICATION_NAME "service"

#define CONFIG_SECTION_NAME "process/NiceHash"

#define MAIL_BOT_USERNAME "mailbot"
#define API_BOT_USERNAME "apibot"
#define ADMIN_USERNAME "admin"

#define API_BOT_USERNAME "apibot"

extern "C++" {

namespace Apostol {

    namespace Processes {

        //--------------------------------------------------------------------------------------------------------------

        //-- CNiceHash ---------------------------------------------------------------------------------------------

        //--------------------------------------------------------------------------------------------------------------

        CNiceHash::CNiceHash(CCustomProcess *AParent, CApplication *AApplication):
                inherited(AParent, AApplication, "NiceHash process") {

            m_Agent = "NiceHash Bot";
            m_Host = CApostolModule::GetIPByHostName(CApostolModule::GetHostName());

            const auto now = Now();

            m_AuthDate = now;

            m_HeartbeatInterval = 5000;
        }
        //--------------------------------------------------------------------------------------------------------------

        void CNiceHash::InitializeNHBot(const CString &Title) {
            
            m_Server.ServerName() = Title;
            m_Server.PollStack(PQServer().PollStack());

            m_Server.DefaultIP() = Config()->Listen();
            m_Server.DefaultPort(Config()->IniFile().ReadInteger(CONFIG_SECTION_NAME, "port", Config()->Port()));

#if defined(_GLIBCXX_RELEASE) && (_GLIBCXX_RELEASE >= 9)
            m_Server.OnVerbose([this](auto && Sender, auto && AConnection, auto && AFormat, auto && args) { DoVerbose(Sender, AConnection, AFormat, args); });
            m_Server.OnAccessLog([this](auto && AConnection) { DoAccessLog(AConnection); });
            m_Server.OnException([this](auto && AConnection, auto && AException) { DoException(AConnection, AException); });
            m_Server.OnEventHandlerException([this](auto && AHandler, auto && AException) { DoServerEventHandlerException(AHandler, AException); });
            m_Server.OnNoCommandHandler([this](auto && Sender, auto && AData, auto && AConnection) { DoNoCommandHandler(Sender, AData, AConnection); });

            m_Server.OnRead([this](auto && Server, auto && Socket, auto && Buffer) { DoRead(Server, Socket, Buffer); });
            m_Server.OnWrite([this](auto && Server, auto && Socket, auto && Buffer) { DoWrite(Server, Socket, Buffer); });
#else
            m_Server.OnVerbose(std::bind(&CNiceHash::DoVerbose, this, _1, _2, _3, _4));
            m_Server.OnAccessLog(std::bind(&CNiceHash::DoAccessLog, this, _1));
            m_Server.OnException(std::bind(&CNiceHash::DoException, this, _1, _2));
            m_Server.OnEventHandlerException(std::bind(&CNiceHash::DoServerEventHandlerException, this, _1, _2));
            m_Server.OnNoCommandHandler(std::bind(&CNiceHash::DoNoCommandHandler, this, _1, _2, _3));

            m_Server.OnRead(std::bind(&CNiceHash::DoRead, this, _1, _2, _3));
            m_Server.OnWrite(std::bind(&CNiceHash::DoWrite, this, _1, _2, _3));
#endif
        }
        //--------------------------------------------------------------------------------------------------------------

        void CNiceHash::BeforeRun() {
            sigset_t set;

            Application()->Header(Application()->Name() + ": nicehash process");

            Log()->Debug(APP_LOG_DEBUG_CORE, MSG_PROCESS_START, GetProcessName(), Application()->Header().c_str());

            InitSignals();

            Reload();

            SetUser(Config()->User(), Config()->Group());

            InitializePQServer(Application()->Title());

            PQServerStart("helper");

            SigProcMask(SIG_UNBLOCK, SigAddSet(&set));

            SetTimerInterval(1000);
        }
        //--------------------------------------------------------------------------------------------------------------

        void CNiceHash::AfterRun() {
            CApplicationProcess::AfterRun();
            PQServerStop();
        }
        //--------------------------------------------------------------------------------------------------------------

        void CNiceHash::Run() {

            try {
                m_Server.ActiveLevel(alActive);

                while (!sig_exiting) {

                    Log()->Debug(APP_LOG_DEBUG_EVENT, _T("nicehash process cycle"));

                    try {
                        m_Server.Wait();
                    } catch (std::exception &e) {
                        Log()->Error(APP_LOG_ERR, 0, _T("%s"), e.what());
                    }

                    if (sig_terminate || sig_quit) {
                        if (sig_quit) {
                            sig_quit = 0;
                            Log()->Debug(APP_LOG_DEBUG_EVENT, _T("gracefully shutting down"));
                            Application()->Header(_T("nicehash process is shutting down"));
                        }

                        if (!sig_exiting) {
                            sig_exiting = 1;
                            Log()->Debug(APP_LOG_DEBUG_EVENT, _T("exiting nicehash process"));
                        }
                    }

                    if (sig_reopen) {
                        sig_reopen = 0;

                        Log()->Debug(APP_LOG_DEBUG_EVENT, _T("nicehash reconnect"));

                        m_Server.ActiveLevel(alBinding);
                        m_Server.ActiveLevel(alActive);
                    }
                }
            } catch (std::exception &e) {
                Log()->Error(APP_LOG_ERR, 0, _T("%s"), e.what());
                ExitSigAlarm(5 * 1000);
            }

            Log()->Debug(APP_LOG_DEBUG_EVENT, _T("stop nicehash process"));
        }
        //--------------------------------------------------------------------------------------------------------------

        bool CNiceHash::DoExecute(CTCPConnection *AConnection) {
            return true;
        }
        //--------------------------------------------------------------------------------------------------------------

        ushort CNiceHash::GetCRC16(void *buffer, size_t size) {
            int crc = 0xFFFF;

            for (int i = 0; i < size; i++) {
                crc = crc ^ ((BYTE *) buffer)[i];

                for (int j = 0; j < 8; ++j) {
                    if ((crc & 0x01) == 1)
                        crc = (crc >> 1 ^ 0xA001);
                    else
                        crc >>= 1;
                }
            }

            return (ushort) crc;
        }
        //--------------------------------------------------------------------------------------------------------------

        void CNiceHash::Reload() {
            CServerProcess::Reload();

            m_AuthDate = Now();
        }
        //--------------------------------------------------------------------------------------------------------------

        void CNiceHash::Authentication() {

            auto OnExecuted = [this](CPQPollQuery *APollQuery) {

                CPQueryResults pqResults;
                CStringList SQL;

                try {
                    CApostolModule::QueryToResults(APollQuery, pqResults);

                    m_Session = pqResults[0][0]["session"];
                    m_Secret = pqResults[0][0]["secret"];

                    m_ApiBot = pqResults[1][0]["get_session"];
                    m_MailBot = pqResults[2][0]["get_session"];
                    m_Admin = pqResults[3][0]["get_session"];

                    m_AuthDate = Now() + (CDateTime) 24 / HoursPerDay;

                    m_Status = psRunning;
                } catch (Delphi::Exception::Exception &E) {
                    DoError(E);
                }
            };

            auto OnException = [this](CPQPollQuery *APollQuery, const Delphi::Exception::Exception &E) {
                DoError(E);
            };

            CString Application(SERVICE_APPLICATION_NAME);

            const auto &Providers = Server().Providers();
            const auto &Provider = Providers.DefaultValue();

            m_ClientId = Provider.ClientId(Application);
            m_ClientSecret = Provider.Secret(Application);

            CStringList SQL;

            api::login(SQL, m_ClientId, m_ClientSecret, m_Agent, m_Host);

            api::get_session(SQL, API_BOT_USERNAME, m_Agent, m_Host);
            api::get_session(SQL, MAIL_BOT_USERNAME, m_Agent, m_Host);
            api::get_session(SQL, ADMIN_USERNAME, m_Agent, m_Host);

            try {
                ExecSQL(SQL, nullptr, OnExecuted, OnException);
            } catch (Delphi::Exception::Exception &E) {
                DoError(E);
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CNiceHash::DoTimer(CPollEventHandler *AHandler) {
            uint64_t exp;

            auto LTimer = dynamic_cast<CEPollTimer *> (AHandler->Binding());
            LTimer->Read(&exp, sizeof(uint64_t));

            try {
                DoHeartbeat();
            } catch (Delphi::Exception::Exception &E) {
                DoServerEventHandlerException(AHandler, E);
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CNiceHash::DoError(const Delphi::Exception::Exception &E) {
            const auto now = Now();

            m_Token.Clear();
            m_Session.Clear();
            m_Secret.Clear();

            m_AuthDate = now + (CDateTime) m_HeartbeatInterval / MSecsPerDay;

            Log()->Error(APP_LOG_ERR, 0, "%s", E.what());
        }
        //--------------------------------------------------------------------------------------------------------------

        void CNiceHash::DoHeartbeat() {
            const auto now = Now();

            if ((now >= m_AuthDate)) {
                Authentication();
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CNiceHash::DoException(CTCPConnection *AConnection, const Delphi::Exception::Exception &E) {
            Log()->Error(APP_LOG_ERR, 0, "%s", E.what());
            sig_reopen = 1;
        }
        //--------------------------------------------------------------------------------------------------------------

        CPQPollQuery *CNiceHash::GetQuery(CPollConnection *AConnection) {
            auto pQuery = CServerProcess::GetQuery(AConnection);

            if (Assigned(pQuery)) {
#if defined(_GLIBCXX_RELEASE) && (_GLIBCXX_RELEASE >= 9)
                pQuery->OnPollExecuted([this](auto && APollQuery) { DoPostgresQueryExecuted(APollQuery); });
                pQuery->OnException([this](auto && APollQuery, auto && AException) { DoPostgresQueryException(APollQuery, AException); });
#else
                pQuery->OnPollExecuted(std::bind(&CNiceHash::DoPostgresQueryExecuted, this, _1));
                pQuery->OnException(std::bind(&CNiceHash::DoPostgresQueryException, this, _1, _2));
#endif
            }

            return pQuery;
        }
        //--------------------------------------------------------------------------------------------------------------

        void CNiceHash::DoPostgresQueryExecuted(CPQPollQuery *APollQuery) {
            CPQResult *pResult;

            try {
                for (int I = 0; I < APollQuery->Count(); I++) {
                    pResult = APollQuery->Results(I);

                    if (pResult->ExecStatus() != PGRES_TUPLES_OK)
                        throw Delphi::Exception::EDBError(pResult->GetErrorMessage());
                }
            } catch (std::exception &e) {
                Log()->Error(APP_LOG_ERR, 0, "%s", e.what());
            }
        }
        //--------------------------------------------------------------------------------------------------------------

        void CNiceHash::DoPostgresQueryException(CPQPollQuery *APollQuery, const Delphi::Exception::Exception &E) {
            Log()->Error(APP_LOG_ERR, 0, "%s", E.what());
        }
        //--------------------------------------------------------------------------------------------------------------

    }
}

}
