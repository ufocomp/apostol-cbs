/*++

Program name:

  Apostol Web Service

Module Name:

  NHBot.hpp

Notices:

  Process: NiceHash

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#ifndef APOSTOL_NICEHASH_HPP
#define APOSTOL_NICEHASH_HPP
//----------------------------------------------------------------------------------------------------------------------

extern "C++" {

namespace Apostol {

    namespace Processes {

        //--------------------------------------------------------------------------------------------------------------

        //-- CNiceHash -------------------------------------------------------------------------------------------------

        //--------------------------------------------------------------------------------------------------------------

        class CNiceHash: public CProcessCustom {
            typedef CProcessCustom inherited;

        private:

            CString m_Token;
            CString m_Session;
            CString m_Secret;
            CString m_ClientId;
            CString m_ClientSecret;
            CString m_Agent;
            CString m_Host;

            CDateTime m_AuthDate;

            int m_HeartbeatInterval;

            CUDPAsyncServer m_Server;

            void BeforeRun() override;
            void AfterRun() override;

            static ushort GetCRC16(void *buffer, size_t size);

            void Authentication();
            void Authorize(CStringList &SQL, const CString &Username);

        protected:

            void DoTimer(CPollEventHandler *AHandler) override;

            void DoHeartbeat();
            void DoError(const Delphi::Exception::Exception &E);

            void DoException(CTCPConnection *AConnection, const Delphi::Exception::Exception &E);
            bool DoExecute(CTCPConnection *AConnection) override;

            void DoPostgresQueryExecuted(CPQPollQuery *APollQuery);
            void DoPostgresQueryException(CPQPollQuery *APollQuery, const Delphi::Exception::Exception &E);

        public:

            explicit CNiceHash(CCustomProcess* AParent, CApplication *AApplication);

            ~CNiceHash() override = default;

            static class CNiceHash *CreateProcess(CCustomProcess *AParent, CApplication *AApplication) {
                return new CNiceHash(AParent, AApplication);
            }

            void Run() override;
            void Reload() override;

            CPQPollQuery *GetQuery(CPollConnection *AConnection) override;

        };
        //--------------------------------------------------------------------------------------------------------------

    }
}

using namespace Apostol::Processes;
}
#endif //APOSTOL_NICEHASH_HPP
