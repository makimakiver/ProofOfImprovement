"use client"; // Only needed in the App Router for client components

import React, { useState } from "react";
import type { NextPage } from "next";

/**
 * A simple page for creating a marketplace entry
 * with title, participants, grade types, and end date.
 */
const MarketCreatePage: NextPage = () => {
  // Local state for each field
  const [title, setTitle] = useState("");
  const [participantInput, setParticipantInput] = useState("");
  const [participants, setParticipants] = useState<string[]>([]);
  const [gradeTypeInput, setGradeTypeInput] = useState("");
  const [gradeTypes, setGradeTypes] = useState<string[]>([]);
  const [endDate, setEndDate] = useState("");

  // Handlers for adding multiple participants
  const handleAddParticipant = () => {
    if (participantInput.trim()) {
      setParticipants([...participants, participantInput.trim()]);
      setParticipantInput("");
    }
  };

  // Handlers for adding multiple grade types
  const handleAddGradeType = () => {
    if (gradeTypeInput.trim()) {
      setGradeTypes([...gradeTypes, gradeTypeInput.trim()]);
      setGradeTypeInput("");
    }
  };

  // Form submission handler
  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    // You can handle any on-chain calls or API requests here
    // For now, just log to the console
    console.log({
      title,
      participants,
      gradeTypes,
      endDate,
    });
  };

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Create a Marketplace</h1>
      <form onSubmit={handleSubmit} className="max-w-md mx-auto space-y-6">
        {/* Title */}
        <div>
          <label className="block mb-1 font-medium">Title</label>
          <input
            type="text"
            className="input input-bordered w-full"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Enter market title"
          />
        </div>

        {/* Participants */}
        <div>
          <label className="block mb-1 font-medium">Add participants</label>
          <div className="flex gap-2">
            <input
              type="text"
              className="input input-bordered flex-grow"
              value={participantInput}
              onChange={(e) => setParticipantInput(e.target.value)}
              placeholder="Enter participant wallet"
            />
            <button
              type="button"
              className="btn"
              onClick={handleAddParticipant}
            >
              +
            </button>
          </div>
          <ul className="mt-2 list-disc list-inside">
            {participants.map((p, idx) => (
              <li key={idx}>{p}</li>
            ))}
          </ul>
        </div>

        {/* Grade Types */}
        <div>
          <label className="block mb-1 font-medium">Grade Types</label>
          <div className="flex gap-2">
            <input
              type="text"
              className="input input-bordered flex-grow"
              value={gradeTypeInput}
              onChange={(e) => setGradeTypeInput(e.target.value)}
              placeholder="e.g. A, B, Pass, etc."
            />
            <button
              type="button"
              className="btn"
              onClick={handleAddGradeType}
            >
              +
            </button>
          </div>
          <ul className="mt-2 list-disc list-inside">
            {gradeTypes.map((g, idx) => (
              <li key={idx}>{g}</li>
            ))}
          </ul>
        </div>

        {/* End Date */}
        <div>
          <label className="block mb-1 font-medium">End Date</label>
          <input
            type="date"
            className="input input-bordered w-full"
            value={endDate}
            onChange={(e) => setEndDate(e.target.value)}
          />
        </div>

        {/* Submit */}
        <button type="submit" className="btn btn-primary w-full">
          Submit
        </button>
      </form>
    </div>
  );
};

export default MarketCreatePage;
