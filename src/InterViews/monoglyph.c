/*
 * Copyright (c) 1987, 1988, 1989, 1990, 1991 Stanford University
 * Copyright (c) 1991 Silicon Graphics, Inc.
 *
 * Permission to use, copy, modify, distribute, and sell this software and 
 * its documentation for any purpose is hereby granted without fee, provided
 * that (i) the above copyright notices and this permission notice appear in
 * all copies of the software and related documentation, and (ii) the names of
 * Stanford and Silicon Graphics may not be used in any advertising or
 * publicity relating to the software without the specific, prior written
 * permission of Stanford and Silicon Graphics.
 * 
 * THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND, 
 * EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY 
 * WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  
 *
 * IN NO EVENT SHALL STANFORD OR SILICON GRAPHICS BE LIABLE FOR
 * ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
 * OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
 * WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF 
 * LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE 
 * OF THIS SOFTWARE.
 */

#include <InterViews/monoglyph.h>

MonoGlyph::MonoGlyph(Glyph* glyph) : Glyph() {
    Resource::ref(glyph);
    body_ = glyph;
}

MonoGlyph::~MonoGlyph() {
    Resource::unref(body_);
}

void MonoGlyph::body(Glyph* glyph) {
    Resource::ref(glyph);
    if (body_ != nil) {
	body_->undraw();
	Resource::unref_deferred(body_);
    }
    body_ = glyph;
}

Glyph* MonoGlyph::body() const { return body_; }

void MonoGlyph::bodyclear() {
    Resource::unref(body_);
    body_ = nil;
}

void MonoGlyph::request(Requisition& requisition) const {
    if (body_ != nil) {
        body_->request(requisition);
    } else {
	Glyph::request(requisition);
    }
}

void MonoGlyph::allocate(Canvas* c, const Allocation& a, Extension& ext) {
    if (body_ != nil) {
        body_->allocate(c, a, ext);
    } else {
	Glyph::allocate(c, a, ext);
    }
}

void MonoGlyph::draw(Canvas* c, const Allocation& a) const {
    if (body_ != nil) {
        body_->draw(c, a);
    } else {
	Glyph::draw(c, a);
    }
}

void MonoGlyph::print(Printer* p, const Allocation& a) const {
    if (body_ != nil) {
        body_->print(p, a);
    } else {
	Glyph::print(p, a);
    }
}

void MonoGlyph::pick(Canvas* c, const Allocation& a, int depth, Hit& h) {
    if (body_ != nil) {
        body_->pick(c, a, depth, h);
    } else {
        Glyph::pick(c, a, depth, h);
    }        
}

void MonoGlyph::undraw() {
    if (body_ != nil) {
	body_->undraw();
    }
}

void MonoGlyph::append(Glyph* glyph) {
    if (body_ != nil) {
        body_->append(glyph);
    }
}

void MonoGlyph::prepend(Glyph* glyph) {
    if (body_ != nil) {
        body_->prepend(glyph);
    }
}

void MonoGlyph::insert(GlyphIndex index, Glyph* glyph) {
    if (body_ != nil) {
        body_->insert(index, glyph);
    }
}

void MonoGlyph::remove(GlyphIndex index) {
    if (body_ != nil) {
        body_->remove(index);
    }
}

void MonoGlyph::replace(GlyphIndex index, Glyph* glyph) {
    if (body_ != nil) {
        body_->replace(index, glyph);
    }
}

GlyphIndex MonoGlyph::count() const {
    if (body_ != nil) {
        return body_->count();
    } else {
        return Glyph::count();
    }
}

Glyph* MonoGlyph::component(GlyphIndex index) const {
    if (body_ != nil) {
        return body_->component(index);
    } else {
        return Glyph::component(index);
    }
}

void MonoGlyph::change(GlyphIndex index) {
    if (body_ != nil) {
        body_->change(index);
    }
}

void MonoGlyph::allotment(
    GlyphIndex index, DimensionName res, Allotment& a
) const {
    if (body_ != nil) {
        body_->allotment(index, res, a);
    } else {
        Glyph::allotment(index, res, a);
    }
}
