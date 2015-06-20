//
//  HeadMountedDisplay.h
//  iosvr
//

#ifndef __IOSVR__HEADMOUNTEDDISPLAY_H__
#define __IOSVR__HEADMOUNTEDDISPLAY_H__

namespace iosvr
{
    class CardboardDeviceParams;
    class ScreenParams;
    class UIScreenExt;

    class HeadMountedDisplay
    {
    public:
        HeadMountedDisplay(UIScreenExt* _screen);
        
        HeadMountedDisplay(const HeadMountedDisplay &other);
        
        HeadMountedDisplay& operator=(const HeadMountedDisplay &other);
        
        bool operator==(const HeadMountedDisplay &other) const;
        bool operator!=(const HeadMountedDisplay &other) const;
        
        virtual ~HeadMountedDisplay();
        
        void setScreen(ScreenParams* _screen);
        ScreenParams *getScreen();
        
        void setCardboard(CardboardDeviceParams *_cardboard);
        CardboardDeviceParams *getCardboard();
        
    private:
        ScreenParams* screen;
        CardboardDeviceParams* cardboard;
    };

}

#endif //__IOSVR__HEADMOUNTEDDISPLAY_H__
