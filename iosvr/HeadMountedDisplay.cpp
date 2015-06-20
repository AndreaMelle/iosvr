//
//  HeadMountedDisplay.cpp
//  iosvr
//


#include "HeadMountedDisplay.h"

#include "CardboardDeviceParams.h"
#include "ScreenParams.h"
#include "UIScreenExt.h"

namespace iosvr
{
    HeadMountedDisplay::HeadMountedDisplay(UIScreenExt *_screen)
    {
        this->screen = new ScreenParams(_screen);
        this->cardboard = new CardboardDeviceParams();
    }
    
    HeadMountedDisplay::HeadMountedDisplay(const HeadMountedDisplay &other)
    {
        this->screen = new ScreenParams(*other.screen);
        this->cardboard = new CardboardDeviceParams(*other.cardboard);
    }
    
    HeadMountedDisplay& HeadMountedDisplay::operator=(const HeadMountedDisplay &other)
    {
        if(*this != other)
        {
            this->screen = new ScreenParams(*other.screen);
            this->cardboard = new CardboardDeviceParams(*other.cardboard);
        }
        
        return *this;
    }
    
    bool HeadMountedDisplay::operator==(const HeadMountedDisplay &other) const
    {
        return (this->screen == other.screen
                && this->cardboard == other.cardboard);
    }
    
    bool HeadMountedDisplay::operator!=(const HeadMountedDisplay &other) const
    {
        return !(*this==other);
    }

    HeadMountedDisplay::~HeadMountedDisplay()
    {
        if (screen != 0) { delete screen; }
        if (cardboard != 0) { delete cardboard; }
    }

    void HeadMountedDisplay::setScreen(ScreenParams* _screen)
    {
        if (this->screen != 0)
        {
            delete this->screen;
        }
        this->screen = new ScreenParams(*_screen);
    }

    ScreenParams* HeadMountedDisplay::getScreen()
    {
        return screen;
    }

    void HeadMountedDisplay::setCardboard(CardboardDeviceParams *_cardboard)
    {
        if (this->cardboard != 0)
        {
            delete this->cardboard;
        }
        this->cardboard = new CardboardDeviceParams(*_cardboard);
    }

    CardboardDeviceParams* HeadMountedDisplay::getCardboard()
    {
        return cardboard;
    }
    
}
