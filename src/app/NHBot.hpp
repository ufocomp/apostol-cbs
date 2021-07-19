/*++

Program name:

  NHBot

Module Name:

  NHBot.hpp

Notices:

  NiceHash Bot

Author:

  Copyright (c) Prepodobny Alen

  mailto: alienufo@inbox.ru
  mailto: ufocomp@gmail.com

--*/

#ifndef APOSTOL_APOSTOL_HPP
#define APOSTOL_APOSTOL_HPP
//----------------------------------------------------------------------------------------------------------------------

#include "../../version.h"
//----------------------------------------------------------------------------------------------------------------------

#define APP_VERSION      AUTO_VERSION
#define APP_VER          APP_NAME "/" APP_VERSION
//----------------------------------------------------------------------------------------------------------------------

#include "Header.hpp"
//----------------------------------------------------------------------------------------------------------------------

extern "C++" {

namespace Apostol {

    namespace ShipSafety {

        class CNiceHashBot: public CApplication {
        protected:

            void ParseCmdLine() override;
            void ShowVersionInfo() override;

            void StartProcess() override;

        public:

            CNiceHashBot(int argc, char *const *argv): CApplication(argc, argv) {

            };

            ~CNiceHashBot() override = default;

            static class CNiceHashBot *Create(int argc, char *const *argv) {
                return new CNiceHashBot(argc, argv);
            };

            inline void Destroy() override { delete this; };

            void Run() override;

        };
    }
}

using namespace Apostol::ShipSafety;
}

#endif //APOSTOL_APOSTOL_HPP

